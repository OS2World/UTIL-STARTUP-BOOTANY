#define Numeric         0x30       /* First numeric value          */
#define BootLocation    0x7C00     /* Address where DOS loads boot */
#define BootSeg         0x7C0      /* Segment where DOS loads boot */
#define NewBootLocation 0x7C00     /* Relocation Address           */
#define NewBootSeg      0x7C0      /* Relocation Segment           */
#define PartAddr        0x1BE      /* Offset to partition table    */
#define ValidationAddr  0x1FE      /* Offset to validation bytes   */
#define KeyboardFlags   0x417      /* Address of keyboard mask     */
#define NumLockOff      0xDF       /* Mask to turn numlock off     */
#define NumLockOn       0xFF       /* Mask to leave numlock on     */
#define max_partitions  3          /* Can't fit any more           */
#define part_text_len   15         /* max bytes for partition desc */

typedef struct PartitionEntry
  {
    char     bootIndicator;
    char     beginHead;
    char     beginSector;
    char     beginCyl;
    char     systemId;
    char     endHead;
    char     endSector;
    char     endCyl;
    short    relSectorLow;
    short    relSectorHigh;
    short    numSectorsLow;
    short    numSectorsHigh;
  } PartitionEntry;

typedef struct PartData
  {
    char     partition;
    char     text[part_text_len];
    char     term;
  } PartData;

#define PartDataLen (sizeof(PartData) * max_partitions)

typedef struct BootData
  {
    PartData       partDesc[max_partitions];
    char           numlockMask;
    PartitionEntry partEntry[4];
  } BootData;

#define DataAddr (ValidationAddr - sizeof(BootData))
