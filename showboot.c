#include <stdio.h>
#include "bootany.h"

#define DISK_READ 2
#define DISK_WRITE 3

extern int bootio(int, char *);

#define SWITCH(var) switch (var)
#define CASE(val) break; case val:
#define ORCASE(val) case val:
#define DEFAULT break; default:

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

#define StandardTable 0
#define BootAnyTable 1

main()
{
  static char head1[] =
     "ÚÄÄÄÄÄÄÂÄÄÄÄÂÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂ"
     "ÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄ¿";
  static char head2[] =
     "³ Part ³Can ³Boot³     Beginning      ³       Ending       ³"
     "Relative ³Number of³";
  static char head3[] =
     "³ Type ³Boot³Part³Side Cylinder Sector³Side Cylinder Sector³"
     "Sectors  ³ Sectors ³";
  static char head4[] =
     "ÃÄÄÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÅÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÅ"
     "ÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄ´";
  static char detail1[] =
     "³%6.6s³%4.4s³%4.4s³%3u ³%7u ³%5u ³%3u ³%7u ³%5u ³%8lu ³%8lu ³";
  static char detail2[] =
     "ÃÄÄÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅ"
     "ÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄ´";
  static char foot[] =
     "ÀÄÄÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁ"
     "ÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÙ";
  char bootRecord[512];
  char buffer[80];
  int  rc;
  int tableType = StandardTable;

   if ((rc = BOOTIO(DISK_READ, bootRecord)) == 0)
     {
       register BootData *bootInfo =
                (BootData *)(bootRecord + DataAddr);
       register PartitionEntry *part = bootInfo->partEntry;
       int i;

       printf(head1);
       printf(head2);
       printf(head3);
       printf(head4);

       for (i = 0; i < 4; ++i)
         {
           int  type;
           char boot;
           char *active;
           char *typeString;
           char *bootString;
           long relSectors;
           long numSectors;

           if (part->bootIndicator == 0 ||
               part->bootIndicator == (char)(0x80))
             {
               type = (int)(part->systemId);
               boot = part->bootIndicator;
               active = (boot == (char)0x80) ? "YES" : " NO";
             }
            else
             {
               active = "NO";
               tableType = BootAnyTable;
               type = (int)(part->bootIndicator);
               boot = part->systemId;
             }

           SWITCH(type)
             {
               CASE(EMPTY)
                 {
                   typeString = "EMPTY ";
                 }
               CASE(FAT_12)
                 {
                   typeString = "DOS-12";
                 }
               CASE(XENIX)
                 {
                   typeString = "XENIX ";
                 }
               CASE(FAT_16)
                 {
                   typeString = "DOS-16";
                 }
               CASE(EXTEND)
                 {
                   typeString = "EXTEND";
                 }
               CASE(BIGDOS)
                 {
                   typeString = "BIGDOS";
                 }
               CASE(HPFS)
                 {
                   typeString = "HPFS  ";
                 }
               CASE(NOVELL)
                 {
                   typeString = "NOVELL";
                 }
               CASE(PCIX)
                 {
                   typeString = "PCIX  ";
                 }
               CASE(CP_M)
                 {
                   typeString = "CP/M  ";
                 }
               CASE(BBT)
                 {
                   typeString = "BBT   ";
                 }
               DEFAULT
                 {
                   typeString = "??????";
                 }
             }

           bootString = (boot == (char)0x80) ? "YES" : " NO";

           relSectors = *(long*)(&part->relSectorLow);
           numSectors = *(long*)(&part->numSectorsLow);

           printf(detail1, typeString, bootString, active,
                  part->beginHead, part->beginCyl, part->beginSector,
                  part->endHead, part->endCyl, part->endSector,
                  relSectors, numSectors);
           if (i < 3)
             {
               printf(detail2);
             }
           ++part;
         }
       printf(foot);
     }
    else
     {
       printf("Error reading boot record - rc = %d\n",rc);
     }
}
