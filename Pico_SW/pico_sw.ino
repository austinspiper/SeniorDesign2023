/** \file pico_sw.ino
 * A brief file description.
 * Senior design project
 * Austin Piper, Ryan Cheevers, Oliver Bergman
 */
#include <stdio.h>
#include <SD.h>

#define PIN_SD_MISO 12
#define PIN_SD_MOSI 11
#define PIN_SD_SCK 14
#define PIN_SD_CE 17

#define PIN_FPGA_MISO 0
#define PIN_FPGA_MOSI 1
#define PIN_FPGA_SCK 2
#define PIN_FPGA_CE 4

#define PIN_WRITING_IND 25

#define PIN_RESET 3

uint8_t msg_toggle_prot[] = {0x02};
// Try max SPI clock for an SD. Reduce SPI_CLOCK if errors occur.
#define SPI_CLOCK SD_SCK_MHZ(1)

#define SD_CONFIG SdSpiConfig(PIN_WRITING_IND, DEDICATED_SPI, SPI_CLOCK)
#define ROM_NAME "selection.nes"

#define SPI_TRANSFER_LIMIT 512
#define GET_BIT(x,y) (x>>y) & 0x01

typedef struct
{
  uint8_t mirroring_type : 1;
  uint8_t nvm_present : 1;
  uint8_t trainer : 1;
  uint8_t hw_four_screened_md : 1;
  uint8_t mapper_num_lsb : 4;
} NESHeaderFlags6 __attribute__((packed));

typedef struct
{
  uint8_t console_type : 2;
  uint8_t rom_ver : 2;
  uint8_t mapper_num_msb : 8;
  uint8_t sub_mapper_num : 4;
} NESHeaderFlags7 __attribute__((packed));

typedef struct
{
  uint8_t prg_rom_sz : 4;
  uint8_t chr_rom_sz : 4;
} NESHeaderPrgChrSzMSB __attribute__((packed));

typedef struct
{
  uint8_t ram_sz : 4;
  uint8_t nvram_sz : 4;
} NESHeaderRamSz __attribute__((packed));

typedef union
{
  struct
  {
    uint8_t ppu_type : 4;
    uint8_t hw_type : 4;
  };

  struct
  {
    uint8_t extended_con_type : 4;
    uint8_t : 4;
  };
} NESHeaderSysType __attribute__((packed));

typedef struct
{
  uint8_t num_misc_roms : 2;
  uint8_t : 6;
  uint8_t default_exp_device : 6;
  uint8_t : 2;
} NESHeaderMisc __attribute__((packed));

typedef struct
{
  char identifier[4];
  uint8_t prg_rom_sz_lsb;
  uint8_t chr_rom_sz_lsb;
  NESHeaderFlags6 flags6;
  NESHeaderFlags7 flags7;
  NESHeaderPrgChrSzMSB rom_sz_msb;
  NESHeaderRamSz prg_ram_sz;
  NESHeaderRamSz chr_ram_sz;
  uint8_t timing;
  NESHeaderSysType sys_type;
  NESHeaderMisc misc;
} NESRomHeader __attribute__((packed));

typedef struct
{
  uint32_t offset;
  uint32_t size;
} RomSection;

struct NESRom
{
  NESRomHeader header;
  RomSection prg_rom;
  RomSection chr_rom;
  RomSection misc_rom;
};

/** 
 * @brief sends data or commands depending on which is specified over spi to FPGA
 * @param buffer_in: buffer for outgoing data (incoming from fpga perspective)
 * @param buffer_out: buffer for incoming data (outgoing from fpga perspective)
 * @param cnt: how many bytes in the buffer
 * @param commit_after_each: whether the FPGA should record this data, ie. true if sending rom data, false if sending commands
 */
void send_data(uint8_t buffer_in[], uint8_t buffer_out[], uint16_t cnt, bool commit_after_each)
{
  digitalWrite(PIN_FPGA_CE, LOW);
  delayMicroseconds(1);
  for(uint16_t i=0; i < cnt; i++)
  {
    uint8_t byte_in = 0x00;
    for(uint8_t b=0; b < 8; b++)
    {
      digitalWrite(PIN_FPGA_SCK, LOW);
      delayMicroseconds(1);
      digitalWrite(PIN_FPGA_MOSI, GET_BIT(buffer_in[i], 7-b));
      delayMicroseconds(1);
      byte_in = (byte_in<<1) | digitalRead(PIN_FPGA_MISO);
      delayMicroseconds(1);
      digitalWrite(PIN_FPGA_SCK, HIGH);
      delayMicroseconds(1);
    }
    buffer_out[i] = byte_in;
    if(commit_after_each == true && i < cnt-1)
    {
        delayMicroseconds(1);
        digitalWrite(PIN_FPGA_CE, HIGH);
        delayMicroseconds(1);
        digitalWrite(PIN_FPGA_CE, LOW);
        delayMicroseconds(1);
    }
  }
  delayMicroseconds(1);
  digitalWrite(PIN_FPGA_CE, HIGH);
}

/** 
 * @brief sends data and commands required for FPGA to save the data over spi to FPGA
 * @param buffer_in: buffer for outgoing data (incoming from fpga perspective)
 * @param buffer_out: buffer for incoming data (outgoing from fpga perspective)
 * @param adr: where the data of the first byte in the buffer should be stored, the rest of the data will be stored sequentially
 * @param len: how many bytes are in the buffer
 * @param cpu: true if should be written to the cpu rom, false if it should be written to the ppu rom
 * @param wr: true to write the data from the buffer_in to the fpga starting at adr, false to read the data from the fpga to 
 * buffer_out starting at adr
 */
void write_data(uint8_t buffer_in[], uint8_t buffer_out[], uint16_t adr, uint16_t len, bool cpu, bool wr)
{
  uint8_t op[] = {(uint8_t)(adr >> 8), (uint8_t)(adr & 0xFF), (uint8_t)(cpu ? (wr ? 0x00 : 0x03) : (wr ? 0x01 : 0x04))};
  uint8_t leng[] = {(uint8_t)(len >> 8), (uint8_t)(len & 0xFF)};
  send_data(op, NULL, 3, false);
  send_data(leng, NULL, 2, false);

  send_data(buffer_in, buffer_out, len, true);
}

/**
 * @brief calculates rom size
 * @param msb: most significant rom size byte from header
 * @param lsb: least significant rom size byte from header
 * @return rom size
 */
uint32_t Calc_Rom_Size(uint8_t msb, uint8_t lsb)
{
  uint32_t calculated_size = 0;
  if (msb == 0x0F)
  {
    uint8_t multiplier = lsb & 0x03;
    uint8_t exponent = lsb >> 2;
    calculated_size = (1 << exponent) * (multiplier * 2 + 1);
  }
  else
  {
    calculated_size = (msb << 8) | lsb;
  }

  return calculated_size;
}

/**
 * @brief parses rom
 * @param rom: rom file
 * @param file_size: size of the rom file
 * @return rom object
 */
void init_rom(NESRom *rom, uint32_t file_size)
{
  uint32_t prg_rom_size = 16384*Calc_Rom_Size(rom->header.rom_sz_msb.prg_rom_sz, rom->header.prg_rom_sz_lsb);
  uint32_t chr_rom_size = 8192*Calc_Rom_Size(rom->header.rom_sz_msb.chr_rom_sz, rom->header.chr_rom_sz_lsb);
  uint16_t trainer_size = 0;

  if (rom->header.flags6.trainer == true)
  {
    trainer_size = 512;
  }

  uint32_t misc_rom_size = file_size - 16 - trainer_size - prg_rom_size - chr_rom_size;

  rom->prg_rom.offset = 16 + trainer_size;
  rom->prg_rom.size = prg_rom_size;
  rom->chr_rom.offset = rom->prg_rom.offset + rom->prg_rom.size;
  rom->chr_rom.size = chr_rom_size;
  rom->misc_rom.offset = rom->chr_rom.offset + rom->chr_rom.size;
  rom->misc_rom.size = misc_rom_size;
}

/**
 * @brief connect to serial, sd card reader, fpga, open file, parse data, send data to fpga
 */
void setup() {

  int incomingByte = 0;
  pinMode(PIN_RESET,OUTPUT);
  pinMode(PIN_SD_SCK,OUTPUT);
  pinMode(PIN_SD_CE,OUTPUT);
  pinMode(PIN_FPGA_MISO,INPUT);
  pinMode(PIN_FPGA_SCK,OUTPUT);
  pinMode(PIN_FPGA_MOSI,OUTPUT);
  pinMode(PIN_FPGA_CE,OUTPUT);
  digitalWrite(PIN_SD_CE,HIGH);
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
  Serial.print("Initializing SD card...");
  delay(1000);
  while (!SD.begin(PIN_SD_CE)) {
    Serial.println("initialization failed!");
    delay(1000);
  }
  Serial.println("initialization done.");

  digitalWrite(PIN_RESET, LOW);
  delay(600);
  digitalWrite(PIN_RESET, HIGH);
  delay(600);
}

void loop() {
  int incomingByte = 0;
  if (Serial.available() > 0) {
    incomingByte = Serial.read();
  }
  File rom_file = SD.open(ROM_NAME);
  uint32_t file_size = rom_file.size();
  NESRom rom = {};
  rom_file.read((uint8_t*)&(rom.header), sizeof(rom.header));
  init_rom(&rom, file_size);

  rom_file.seek(rom.prg_rom.offset);
  uint32_t num_msgs = (uint32_t)ceil(rom.prg_rom.size / SPI_TRANSFER_LIMIT);
  send_data(msg_toggle_prot, NULL, 1, false);
  uint16_t bytes_transfered = 0;
  for (uint32_t i = 0; i < num_msgs; i++)
  {
    const uint16_t bytes_left = rom.prg_rom.size - bytes_transfered;
    const uint16_t bytes_to_transfer = bytes_left < SPI_TRANSFER_LIMIT ? bytes_left : SPI_TRANSFER_LIMIT;
    uint8_t data_in[bytes_to_transfer] = {0,};
    uint8_t data[bytes_to_transfer] = {0,};
    rom_file.read(data, bytes_to_transfer);
    
    write_data(data_in,data,bytes_transfered,bytes_to_transfer,true,true);
    bytes_transfered += bytes_to_transfer;
  }

  rom_file.seek(rom.chr_rom.offset);
  num_msgs = (uint32_t)ceil(rom.chr_rom.size / SPI_TRANSFER_LIMIT);
  
  bytes_transfered = 0;
  for (uint32_t i = 0; i < num_msgs; i++)
  {
    const uint16_t bytes_left = rom.chr_rom.size - bytes_transfered;
    const uint16_t bytes_to_transfer = bytes_left < SPI_TRANSFER_LIMIT ? bytes_left : SPI_TRANSFER_LIMIT;

    uint8_t data[bytes_to_transfer] = {0,};

    rom_file.read(data, bytes_to_transfer);

    uint8_t data_in[bytes_to_transfer] = {0,};
    write_data(data_in,data,bytes_transfered,bytes_to_transfer,false,true);
    bytes_transfered += bytes_to_transfer;
  }
  send_data(msg_toggle_prot, NULL, 1, false);

}
