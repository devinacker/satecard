SV_CONTROL     = $2194
SV_GPIO        = $2197
ATA_DATA       = $21A0
ATA_ERROR      = $21A1
ATA_FEATURE    = $21A1
ATA_SECCOUNT   = $21A2
ATA_SECTOR     = $21A3
ATA_CYLINDER   = $21A4
ATA_CYLINDERH  = $21A5
ATA_HEAD       = $21A6
ATA_COMMAND    = $21A7
ATA_STATUS     = $21A7
ATA_STATUS_ALT = $21AE
ATA_CONTROL    = $21AE
ATA_ADDRESS    = $21AF

SECTOR_SIZE    = 512

.globalzp CardRWBuffer

.global CardReset
.global CardDetect
.global CardIRQEnable, CardIRQDisable
.global CardLEDEnable, CardLEDDisable

.global CardReadInfo
.global CardReadSectors
