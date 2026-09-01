# HANDOFF: Doom Emacs font-lock dla IDesign use-case diagrams

## Cel

Stworzyć minor mode w Doom Emacs kolorujący diagramy aktywności w notacji IDesign (bloki ` ```use-case ` w Markdown, komentarze `# ` w TOML).

## Środowisko

- Doom config: `~/.config/doom/` (`config.el`, `init.el`, `packages.el`)
- Doom modules aktywne: `evil`, `vertico`, `(popup +defaults)`, `markdown` (sprawdź w `init.el` w `:lang`)
- Nie modyfikuj `init.el` (module flags). Wszystko przez `config.el` + plik mode'a.

## Notacja do pokolorowania

Diagram żyje w bloku ` ```use-case ` (Markdown) lub w komentarzach `# ` (TOML). Tokeny:

| Token | Znaczenie | Sugerowana face |
|---|---|---|
| `(END <label>)` | zakończenie z wartością/labelką (jak `return`) | `font-lock-type-face` (cyan) |
| `[Action]` | akcja / wywołanie serwisu | `font-lock-function-name-face` (blue) |
| `<condition?>` | decyzja tak/nie (z `?`) | `font-lock-keyword-face` (magenta) |
| `<condition>` | warunek guard (bez `?`) | `font-lock-constant-face` |
| `<_>` | else / default | `font-lock-warning-face` (orange) |
| `|` | fork (początek gałęzi równoległej) | `font-lock-builtin-face` |
| `{GOTO [Name]}` | skok do nazwanego bloku | `font-lock-preprocessor-face` |
| `->` | synchroniczne wywołanie | `font-lock-operator` / dimmed |

Uwaga: nie ma już `(START)` ani `(STOP)` — zakończenia to zawsze `(END ...)`.

## Przykład do przetestowania

```
<user not admin>
  (END NotAllowed)
<name is not unique>
  (END BadRequest)
[Store in OrgModelAccess]
(END Ok of id)
```

I przykład z fork/join + GOTO:

```
[Get cart]
<credit exceeded> {GOTO [MFA]}
<_>
  | [Reserve stock]
    <out of stock>
      [Cancel]
      (END Cancelled)
  | [Charge card]
    <payment error>
      (END PaymentError)
[Send confirmation]
(END Ok of order_id)
```

## Zakres zadania

1. Stwórz `~/.config/doom/use-case-mode.el` z `use-case-font-lock-keywords`. Używaj `rx`, nie stringów regex.
2. Hookuj w `config.el` tak, żeby font-lock działał wewnątrz bloków ` ```use-case ` w `markdown-mode`. Jeśli `poly-markdown` jest dostępne — użyj; jeśli nie — wystarczy ręczne włączanie minor mode'a w bloku (można przez `mmm-mode` albo prosty `markdown-fontify-code-blocks-mode`). Dla TOML: hook na `conf-toml-mode` jest opcjonalny, drugi priorytet.
3. **Nie dotykaj** `init.el`.
4. Przetestuj na pliku `.md` z blokiem ` ```use-case ` — otwórz w Emacsie i sprawdź kolory.
5. Po zakończeniu: podaj komendę reload (`doom sync` lub `SPC q r`).

## Uwagi techniczne

- Koloruj **tokeny**, nie całe linie — line-based font-lock zepsuje wcięcia.
- `|` koloruj tylko jeśli jest first-non-whitespace w linii.
- `[Name]` wewnątrz `{GOTO [Name]}` powinno dziedziczyć face z `[Action]`.
- Labelka po `(END ` — koloruj jako string/type face.
