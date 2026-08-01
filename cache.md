# Cache

Entry:

név|típus|
-|-|
latestElement|idő|
createdAt|idő|
response|Json|

Legutóbbi = Legutóbbi sikeres adatlekérdezés listájának legfrissebb elemének ideje.

## Timetable

TimetableDay entry.

Frissíteni|Korábbi|Múlt hét|Jelenlegi hét|Jövő hét|Későbbi|
-|-|-|-|-|-|
belépéskor?|✖️|✖️|✔️|✔️|✖️|
kijelzéskor?|✖️|✖️|✖️|✖️|✔️|

Új mulasztáskor a mulasztás napját MINDIG frissíti.

## Értékelések/Tesztek/Faliújság/Feljegyzések/Házi feladatok

Frissíteni|Korábbi|Legutóbbi létrehozástól|
-|-|-|
belépéskor?|✖️|✔️|
kijelzéskor?|✖️|✖️|

## Mulasztások

Összes

## Egyéb

Belépéskor

--------
# IMPL

### GenericCache
Entry:
név|típus|
-|-|
userId|id|
createdAt|idő|
response|Json|
