#include <SD.h>

#define CALC_RAM_SIZE(shift_count) 64 << shift_count

#define PIN_SD_MISO 4
#define PIN_SD_MOSI 7
#define PIN_SD_SCK 6

#define PIN_FPGA_MISO 4
#define PIN_FPGA_MOSI 7
#define PIN_FPGA_SCK 6

#define PIN_VBUS_SENSE 24

#define PIN_WRITING_IND 25

// Try max SPI clock for an SD. Reduce SPI_CLOCK if errors occur.
#define SPI_CLOCK SD_SCK_MHZ(50)

#define SD_CONFIG SdSpiConfig(PIN_WRITING_IND, DEDICATED_SPI, SPI_CLOCK)

#define DEBUG_ROM_NAME "debug.nes"

#define SPI_TRANSFER_LIMIT 512

typedef enum
{
  CMD_GET_VERSIONS = 0,
  CMD_CFG = 1,
  CMD_UPDATE_FPGA = 2
} CommandOp;

typedef enum
{
  PPU = 0,
  CPU = 1,
  EXP = 2
} FPGABus;

typedef struct
{
  FPGABus bus;
  uint16_t address;
  uint16_t size;
  uint8_t *data;
  uint8_t crc;
} FPGAMessage __attribute__((packed));


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
  uint8_t mapper_number : 4;
  uint8_t submapper_number : 4;
} NESMapper __attribute__((packed));

typedef struct
{
  char identifier[4];
  uint8_t prg_rom_sz_lsb;
  uint8_t chr_rom_sz_lsb;
  NESHeaderFlags6 flags6;
  NESHeaderFlags7 flags7;
  NESMapper mapper;
  NESHeaderPrgChrSzMSB rom_sz_msb;
  NESHeaderRamSz prg_ram_sz;
  NESHeaderRamSz chr_ram_sz;
  uint8_t timing;
  NESHeaderSysType sys_type;
  NESHeaderMisc misc;
  uint8_t DefaultExpDevice;
} NES2RomHeader __attribute__((packed));

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

struct NES2Rom
{
  NES2RomHeader header;
  RomSection prg_rom;
  RomSection chr_rom;
  RomSection misc_rom;
};

SPISettings spisettings(1000000, MSBFIRST, SPI_MODE0);

void setup() {
  Serial.begin(115200);
  // Wait for USB Serial
  while (!Serial)
  {
    yield();
  }

  Serial.print("[LOG] Initializing SD card...");
  SPI.setRX(PIN_SD_MISO);
  SPI.setTX(PIN_SD_MOSI);
  SPI.setSCK(PIN_SD_SCK);
  SPI.begin(true);
  // Initialize the SD.
  if (!SD.begin(PIN_WRITING_IND))
  {
    Serial.println("[LOG] SD Card Initialization Failed!");
  }
  Serial.println("[LOG] SD Card Initialization Complete.");

  SPI1.setRX(PIN_FPGA_MISO);
  SPI1.setTX(PIN_FPGA_MOSI);
  SPI1.setSCK(PIN_FPGA_SCK);
  SPI1.begin(true);

}

void Send_FPGA_Message(FPGAMessage* msg)
{
  SPI1.beginTransaction(spisettings);
  SPI1.transfer(&msg->bus, sizeof(msg->bus));
  SPI1.transfer(&msg->address, sizeof(msg->address));
  SPI1.transfer(&msg->size, sizeof(msg->size));
  SPI1.transfer(msg->data, msg->size);
  SPI1.transfer(&msg->crc, sizeof(msg->crc));
  SPI1.endTransaction();
}

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

void init_rom(NESRom *rom, uint32_t file_size)
{
  uint32_t prg_rom_size = 16384 * Calc_Rom_Size(rom->header.rom_sz_msb.prg_rom_sz, rom->header.prg_rom_sz_lsb);
  uint32_t chr_rom_size = 8192 * Calc_Rom_Size(rom->header.rom_sz_msb.chr_rom_sz, rom->header.chr_rom_sz_lsb);
  uint16_t trainer_size = 0;

  if (rom->header.flags6.trainer == true)
  {
    trainer_size = 512;
  }

  uint32_t misc_rom_size = file_size - 16 - trainer_size - prg_rom_size - chr_rom_size;

  rom->prg_rom.offset = sizeof(rom->header) + trainer_size;
  rom->prg_rom.size = prg_rom_size;
  rom->chr_rom.offset = rom->prg_rom.offset + rom->prg_rom.size;
  rom->chr_rom.size = chr_rom_size;
  rom->misc_rom.offset = rom->chr_rom.offset + rom->chr_rom.size;
  rom->misc_rom.size = misc_rom_size;
}

void loop() {
  File rom_file = SD.open(DEBUG_ROM_NAME);
  uint32_t file_size = rom_file.size();
  NESRom rom = {};
  rom_file.read((uint8_t*)&(rom.header), sizeof(rom.header));
  init_rom(&rom, file_size);

  rom_file.seek(rom.prg_rom.offset);
  uint32_t num_msgs = (uint32_t)ceil(rom.prg_rom.size / SPI_TRANSFER_LIMIT);

  uint16_t bytes_transfered = 0;
  for (uint32_t i = 0; i < num_msgs; i++)
  {
    const uint16_t bytes_left = rom.prg_rom.size - bytes_transfered;
    const uint16_t bytes_to_transfer = bytes_left < SPI_TRANSFER_LIMIT ? bytes_left : SPI_TRANSFER_LIMIT;

    uint8_t data[bytes_to_transfer] = {0,};
    rom_file.read(data, bytes_to_transfer);

    FPGAMessage msg 
    {
      .bus = CPU,
      .address = bytes_transfered,
      .size = bytes_to_transfer,
      .data = data,
      .crc = 0x00
    };
    Send_FPGA_Message(&msg);

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

    FPGAMessage msg 
    {
      .bus = PPU,
      .address = bytes_transfered,
      .size = bytes_to_transfer,
      .data = data,
      .crc = 0x00
    };
    Send_FPGA_Message(&msg);

    bytes_transfered += bytes_to_transfer;
  }
  rom_file.close();
}
