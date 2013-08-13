#include <stdio.h>
#include "bootany.h"

#define DISK_READ 2
#define DISK_WRITE 3
#define TRUE  1
#define FALSE 0

extern int bootio(int, char *);

#define EMPTY  0
#define FAT_12 1
#define XENIX  2
#define FAT_16 4
#define EXTEND 5
#define BIGDOS 6
#define HPFS   7
#define NOVELL 0x64
#define PCIX   0x75
#define CP_M   0xDB
#define BBT    0xFF

main()
{
  static char msg[] =
     "All bootable partitions have been invalidated\n";
  static char msg1[] =
     "No bootable partitions are defined\n";
  char bootRecord[512];
  int  rc;
  int  update = FALSE;

   if ((rc = BOOTIO(DISK_READ, bootRecord)) == 0)
     {
       register BootData *bootInfo =
                (BootData *)(bootRecord + DataAddr);
       register PartitionEntry *part = bootInfo->partEntry;
       int i;

       for (i = 0; i < 4; ++i)
         {
           char type;
           char boot;

           if (part->bootIndicator == 0 ||
               part->bootIndicator == (char)(0x80))
             {
               type = part->systemId;
               boot = part->bootIndicator;
             }
            else
             {
               type = part->bootIndicator;
               boot = part->systemId;
             }

           if (boot == (char)(0x80))
            {
              update = TRUE;
              part->bootIndicator = type;
              part->systemId = boot;
            }
           ++part;
         }

       if (update)
         {
           if ((rc = BOOTIO(DISK_WRITE, bootRecord)) == 0)
             {
               printf(msg);
             }
            else
             {
               printf("Error updating boot record - rc = %d\n",rc);
             }
         }
        else
         {
           printf(msg1);
         }
     }
    else
     {
       printf("Error reading boot record - rc = %d\n",rc);
     }
}
