# City picker (Город и часовой пояс)

Source: Paper file "EasyBooking", page "EasyBooking · Mobile".

- `13a · Город — выбор`: default state, opened from screen 13.
- `13b · Город — ничего не найдено`: no-results state.

Both artboards sit to the left of row 3 (x -1634 and -1124, y 964).

## Purpose

On screen 13 «Ваш аккаунт», tapping the field «Город и часовой пояс» (value «Алматы · UTC+5») opens a modal bottom sheet. The user picks one Kazakhstan city. Tapping a row selects that city and closes the sheet immediately. The sheet has no confirm button. The field then shows `<Город> · UTC+5`.

## Form

The picker is a modal bottom sheet over screen 13, not a full-screen route.

- The sheet is 870px tall on a 430×932 artboard, so it nearly fills the screen.
- The status bar stays visible behind the scrim, which tells the user this is a temporary choice inside the flow.
- In Flutter, use `showModalBottomSheet` with `isScrollControlled: true` and `useSafeArea: true`. The sheet scrolls internally.
- It closes on: a row tap (returns the city), the close button, a scrim tap, or a drag down (these return `null`).

## Structure

```
CityPickerScreenOverlay (screen 13 unchanged underneath)
├─ Scrim                       full screen, var(--color-text) #222222 at 40% (--opacity-disabled)
└─ CityPickerSheet             width 430, height 870, bg --color-background #FFFFFF,
   │                           top radius --radius-16 (16), column, clip
   ├─ DragHandle               padding top --spacing-12 (12), bottom --spacing-4 (4), centered
   │  └─ Handle                32×4 (--spacing-32 × --spacing-4), radius --radius-999, --color-border #DDDDDD
   ├─ SheetHeader              row, align center, gap 16, padding L 24 / R 12 / T 8
   │  ├─ Titles                column, gap 4, expanded
   │  │  ├─ Title «Город»      Inter 18 / 600 / 24, --color-text   (AppTypography.sectionTitle)
   │  │  └─ Subtitle «Часовой пояс подставим по городу»
   │  │                        Inter 14 / 400 / 20, --color-secondary #6A6A6A (AppTypography.body)
   │  └─ Icon button · close   44×44 target, 22px X icon, stroke 1.7 --color-text
   ├─ SearchSlot               padding H 24, T 16, B 8
   │  └─ CitySearchField       existing search pill (AppSearchField): radius 999, min height 66,
   │                           padding 18h/12v, 1px --color-border, 20px search icon, gap 12
   │                           hint «Найти город» 14/500/20 --color-text
   │                           subtitle «Например, Шымкент» 12/400/20 --color-secondary
   ├─ CityList                 scrollable, padding H 24, fills remaining height
   │  └─ CityListItem ×19      same pattern as the Profile menu rows (AppProfileMenuItem) with no leading icon
   │     ├─ Label              column, gap 2, expanded
   │     │  ├─ City            Inter 15 / 500 / 20, --color-text (600 when selected)
   │     │  └─ TimeZone «UTC+5» Inter 12 / 400 / 20, --color-secondary (AppTypography.caption)
   │     └─ Selection slot     24px wide, right-aligned; 20px check (stroke 2, --color-text) only on the selected row
   │     row: padding V 17 (min height 77), 1px bottom divider --color-border, whole row tappable
   └─ Home indicator           height 38, padding bottom 8, bar 134×5 radius 999 --color-text
```

The close icon and the check share the same right lane: both are centred 34px from the right edge of the sheet.

## Data

These are the cities, in display order. All are UTC+5, because Kazakhstan has used a single time zone since March 2024.

Алматы, Астана, Шымкент, Караганда, Актобе, Тараз, Павлодар, Усть-Каменогорск, Семей, Атырау, Костанай, Кызылорда, Уральск, Петропавловск, Актау, Туркестан, Талдыкорган, Кокшетау, Конаев.

The secondary text comes from the city's offset, formatted as `UTC+5`. The time zone should be data, not hard-coded text in the widget.

## States

| State | Artboard | Description |
|---|---|---|
| Default (empty query) | 13a | The full list, with the current city («Алматы») checked and its name at weight 600. The list is clipped mid-row («Семей») to show that it scrolls. |
| Filtering (query matches) | not drawn | The same list, showing only the matching rows in their original order. The check stays on the current city if it is visible. |
| No results | 13b | The search field is focused and filled: 2px `--color-text` border, padding 9 on the top, bottom and right. The query text is 16/400/24 `--color-text`. A trailing 44×44 clear button (20px X, `--color-secondary`) replaces the hint subtitle. The list area shows `CityEmptyState`. |
| Selected row | 13a, «Алматы» | A check in the trailing slot and the city name at weight 600. |
| Pressed row | not drawn | `AppTheme` has no splash. Use the existing pressed treatment of `AppProfileMenuItem`, if it has one, and add nothing new. |

There are no loading or error states. The list is a static local constant, so nothing can fail to load. If the list later comes from the backend, reuse the loading skeleton and error callout from the "05 · Feedback & Status" artboard.

### CityEmptyState (reuses AppEmptyState)

- Container: `--color-surface` #F7F7F7, radius 12 (`--radius-12`), height 188, column centred, gap 8. It sits 16px below the search slot.
- Icon: 28px search glyph, stroke 1.6, #222222.
- Title «Город не найден»: Inter 16 / 600 / 24, #000000.
- Message «Проверьте написание. Пока доступны только города Казахстана.»: Inter 13 / 400 / 20, `--color-secondary`, centred, max width 260.
- Action «Очистить поиск»: Inter 14 / 600 / 20, #000000, underlined. It clears the query and restores the full list. Keep the field focused.

## Interaction

- **Open:** tap the «Город и часовой пояс» field on screen 13. The sheet opens with an empty query and the current city checked. Scroll the list so the selected row is visible if it is below the fold.
- **Search:** filtering is live on every change.
  - Matching is case-insensitive and by substring on the city name, so a prefix also matches. For example, «ка» matches Караганда, Усть-Каменогорск, Кокшетау and others.
  - Trim leading and trailing whitespace before matching.
  - Treat «ё» as «е».
  - Match the hyphen literally, so «усть-» matches Усть-Каменогорск.
  - An empty or whitespace-only query shows the full list.
- **Clear:** the clear (X) button inside the field, or «Очистить поиск» in the empty state, empties the query and shows the full list.
- **Select:** tapping anywhere on a row returns that city and closes the sheet straight away. Screen 13 then updates the field value to `<Город> · UTC+5`. There is no confirm button.
- **Dismiss without a change:** the close button, a scrim tap, a drag down, or system back. The previous value stays.
- **Keyboard:** the search field is not autofocused on open. When the user focuses it, the sheet stays full height and the list area shrinks above the keyboard.

## Tokens used

- **Colors:**
  - `--color-background` #FFFFFF
  - `--color-text` #222222
  - `--color-secondary` #6A6A6A
  - `--color-border` #DDDDDD
  - `--color-surface` #F7F7F7
  - #000000 (empty-state title, as in the design system and `AppColors.black`)
- **Text sizes:**
  - `--text-12`, `--text-13`, `--text-14`, `--text-16`, `--text-18`
  - 15px for row titles. This size has no token, but the existing Profile menu row (Paper and `AppProfileMenuItem`) already uses it.
- **Weights:** `--font-weight-400`, `--font-weight-500`, `--font-weight-600`.
- **Line heights:** `--leading-20`, `--leading-24`.
- **Spacing:** `--spacing-4`, `--spacing-8`, `--spacing-12`, `--spacing-16`, `--spacing-24`, `--spacing-32`.
- **Radii:** `--radius-12`, `--radius-16`, `--radius-999`.
- **Opacity:** `--opacity-disabled` (40%) for the scrim.

## Values without a dedicated token

- **Scrim color:** `--color-text` at 40%. No scrim token exists, so this reuses the 40% opacity token. Material's default barrier, `Colors.black54`, would also be acceptable if the team prefers it.
- **Row metrics:** 15px row-title size, 17px row vertical padding, and the 2px label gap. These are copied from the Profile menu row.
- **Sheet height:** 870, which is the screen height minus the 62px status bar.
- **Focused search padding:** 9px, so that the 44px clear button fits inside the 66px pill with its 2px focused border.
