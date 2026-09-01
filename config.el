;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!
(set-face-attribute 'default nil :height 140) ;; laptop only
;; (set-face-attribute 'default nil :height 100)
;; (set-face-attribute 'default nil :height 220)

(set-charset-priority 'unicode)
(setq locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(setq default-process-coding-system '(utf-8-unix . utf-8-unix))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one-light)

;; (setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
;; (add-hook 'typescript-mode-hook 'deno-fmt-mode) ;
;; (add-hook 'js2-mode-hook 'deno-fmt-mode)
;;

(keymap-global-set "M-<left>" 'previous-buffer)
(keymap-global-set "M-<right>" 'next-buffer)
(keymap-global-set "S-<left>" 'windmove-left)
(keymap-global-set "S-<right>" 'windmove-right)
(keymap-global-set "S-<up>" 'windmove-up)
(keymap-global-set "S-<down>" 'windmove-down)
(map! :n "] e" #'flycheck-next-error)
(setq global-display-line-numbers 'relative)
(add-hook 'typescript-mode-hook 'deno-fmt-mode)
(add-hook 'js2-mode-hook 'deno-fmt-mode)
(remove-hook 'doom-first-buffer-hook #'smartparens-global-mode)
(setq electric-pair-mode nil)
(remove-hook 'web-mode-hook #'electric-pair-mode)
(remove-hook 'html-mode-hook #'electric-pair-mode)

(defun indent-and-go-down ()
  (interactive)
  (indent-for-tab-command)
  (forward-line 1))

(keymap-global-set "C-\\" 'indent-and-go-down)

;; (setq company-frontends '(company-pseudo-tooltip-unless-just-one-frontend company-preview-frontend))
;; (setq company-frontends '(company-preview-frontend))
;; ((corfu-preselect 'prompt) setq company-idle-delay 0.1
;;         company-tooltip-idle-delay 0.1)


;; (setq corfu-preselect 'prompt)

;; Ensure company is loaded before configuring

(load! "gitea-links.el")
(load! "md-image-paste")
(setq lsp-auto-execute-action nil)

;; (load! "codeium.el")

(defun format-dune-file ()
  "Format the current Dune file using dune format-dune-file."
  (interactive)
  (when (eq major-mode 'dune-mode)
    (let ((file-name (buffer-file-name)))
      (when file-name
        (shell-command (format "dune format-dune-file %s > %s.formatted && mv %s.formatted %s"
                               file-name file-name file-name file-name))
        (revert-buffer :ignore-auto :noconfirm)
        (message "Dune file formatted successfully")))))

(map! :map dune-mode-map
      :leader
      :desc "Format Dune file"
      "m f" #'format-dune-file)

(after! rjsx-mode
  (define-key rjsx-mode-map "<" nil))

;; Well editor tooling lives in ~/.local/bin (well's `make install`).
;; envrc/opam often prepend $OPAM_SWITCH_PREFIX/bin and would shadow the
;; Well-patched ocamlformat-mlx — keep local-bin first, also after envrc.
(defun well/prefer-local-bin ()
  "Put ~/.local/bin first on `exec-path' and PATH."
  (let ((local-bin (expand-file-name "~/.local/bin")))
    (when (file-directory-p local-bin)
      (setq exec-path (cons local-bin (remove local-bin exec-path)))
      (let* ((parts (split-string (or (getenv "PATH") "") path-separator t))
             (parts (cons local-bin (delete local-bin parts))))
        (setenv "PATH" (string-join parts path-separator))))))
(well/prefer-local-bin)
(with-eval-after-load 'envrc
  (add-hook 'envrc-mode-hook #'well/prefer-local-bin))

;; Well MLX formatter: call absolute binary. ocamllsp uses Bin.which on PATH
;; and still hits stock opam ocamlformat-mlx when envrc wins the race.
(defvar well/ocamlformat-mlx
  (expand-file-name "~/.local/bin/ocamlformat-mlx")
  "Well-patched ocamlformat-mlx (keywords + hyphen JSX attrs).")

(defun well/format-mlx-buffer ()
  "Format current .mlx buffer with Well-patched ocamlformat-mlx.
Writes buffer to a temp file, runs the formatter (stdout = result).
Passes --name with the real buffer path so ocamlformat finds the
project .ocamlformat (temp files live under /tmp and have no root)."
  (interactive)
  (unless (and well/ocamlformat-mlx (file-executable-p well/ocamlformat-mlx))
    (user-error "Missing %s — run: cd well && make install" well/ocamlformat-mlx))
  (let* ((input (buffer-substring-no-properties (point-min) (point-max)))
         (tmp (make-temp-file "well-mlx-fmt-" nil ".mlx"))
         (point-was (point))
         (out-buf (generate-new-buffer " *well-ocamlformat-mlx*"))
         ;; Prefer real file path so project root / .ocamlformat is detected.
         (name (or (buffer-file-name)
                   (expand-file-name
                    (concat (or (buffer-name) "buffer") ".mlx")
                    default-directory)))
         (args (list "--name" name tmp))
         exit)
    (unwind-protect
        (progn
          (write-region input nil tmp nil 'silent)
          ;; stdout+stderr -> out-buf; ocamlformat-mlx prints formatted code on stdout
          (setq exit (apply #'call-process well/ocamlformat-mlx nil out-buf nil args))
          (let ((out (with-current-buffer out-buf (buffer-string))))
            (if (zerop exit)
                (unless (string= input out)
                  (let ((inhibit-read-only t)
                        (inhibit-modification-hooks nil))
                    (delete-region (point-min) (point-max))
                    (insert out)
                    (goto-char (min point-was (point-max)))))
              ;; Do not block save; show error in echo area.
              (message "well ocamlformat-mlx failed:\n%s" out))))
      (when (buffer-live-p out-buf) (kill-buffer out-buf))
      (ignore-errors (delete-file tmp)))))

(defun well/mlx-format-on-save ()
  "before-save hook: format mlx without going through ocamllsp."
  (when (and (derived-mode-p 'mlx-mode)
             (file-executable-p well/ocamlformat-mlx))
    (well/format-mlx-buffer)))

;; Format-on-save: .ml via eglot/ocamllsp; .mlx via absolute Well binary
;; (wired in mlx-mode hook — not here, to avoid double-format).
(add-hook 'eglot-managed-mode-hook
          (lambda ()
            (if (derived-mode-p 'mlx-mode)
                (progn
                  (remove-hook 'before-save-hook #'eglot-format-buffer t)
                  ;; Block ocamllsp format for mlx (PATH races with stock binary).
                  (setq-local eglot-ignored-server-capabilities
                              (append '( :documentFormattingProvider
                                         :documentRangeFormattingProvider)
                                      eglot-ignored-server-capabilities)))
              (add-hook 'before-save-hook #'eglot-format-buffer nil t))))

(after! tuareg
  (setq merlin-command "/home/sel/Documents/dg/bin/dune")
  (setq merlin-completion-with-doc t))

;; opam-switch-mode disabled in packages.el - it puts opam's dune 3.21.0
;; in PATH, shadowing the project's dune nightly and hanging ocamllsp

(after! company
  ;; Make completion faster
  (setq company-idle-delay 0.2)              ; Faster trigger
  (setq company-minimum-prefix-length 2)     ; Trigger after 2 chars
  (setq company-tooltip-limit 10)            ; Show fewer candidates
  (setq company-show-quick-access t))        ; Quick selection

(after! company-box
  (setq company-box-enable-icon nil)         ; Disable icons (big speedup!)
  (setq company-box-max-candidates 10)       ; Limit displayed candidates
  (setq company-box-show-single-candidate t)
  (setq company-box-backends-colors nil))    ; Disable colors


(setq help-echo-kludge-around-prompt t)

;; To disabled flycheck popups:
;; (advice-add 'flycheck-popup-tip-mode :around
;;             (lambda (orig-fun &optional arg)
;;               "Prevent flycheck-popup-tip-mode from being enabled"
;;               (when (and (called-interactively-p 'any) (> (or arg 1) 0))
;;                 (funcall orig-fun arg))
;;               (when (not (called-interactively-p 'any))
;;                 (setq flycheck-popup-tip-mode nil))))


;; (use-package! roll)

(map! :after org
      :map org-mode-map
      "<M-right>" nil
      "<M-left>" nil
      "<S-right>" nil
      "<S-left>" nil)

(use-package! envrc
  :hook (after-init . envrc-global-mode)) 

(use-package! mlx-mode
  :mode "\\.mlx\\'"
  :config
  ;; ocamllsp: language-id ocaml.mlx + merlin_reader well.
  ;; Formatting is NOT via ocamllsp — see well/format-mlx-buffer (absolute path).
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
                 '((mlx-mode :language-id "ocaml.mlx") . ("ocamllsp"))))
  :hook
  (mlx-mode . eglot-ensure)
  (mlx-mode . (lambda ()
                (well/prefer-local-bin)
                (add-hook 'before-save-hook #'well/mlx-format-on-save nil t))))

(use-package! ocaml-eglot
  :ensure t
  :after tuareg
  :hook
  (tuareg-mode . ocaml-eglot)
  (ocaml-eglot . eglot-ensure))

(use-package! eee
  :load-path "~/Documents/eval-exec/eee.el/"
  :config
  (setq ee-terminal-command "kitty")
  (map! :leader
        :desc "Open yazi file manager"
        "f f" #'ee-yazi))

;; TSX/TS file associations - override Doom's defaults to use tree-sitter modes
;; Remove the problematic "\\.tsx?\\'" pattern that matches both .ts and .tsx
(setq auto-mode-alist
      (seq-remove (lambda (x) (equal (car x) "\\.tsx?\\'")) auto-mode-alist))
(add-to-list 'auto-mode-alist '("\\.axe\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))

;; IDesign use-case diagram font-lock (```use-case blocks in Markdown)
(load! "use-case-mode")
(after! markdown-mode
  (add-to-list 'markdown-code-lang-modes '("use-case" . use-case-mode))
  (setq markdown-fontify-code-blocks-natively t)
  (add-hook 'markdown-mode-hook #'use-case-mode-enable-in-markdown)
  (add-hook 'gfm-mode-hook #'use-case-mode-enable-in-markdown))
;; Optional: enable use-case-minor-mode in conf-toml-mode when diagrams
;; live in `# ' comments (M-x use-case-minor-mode).

;; ---------------------------------------------------------------------------
;; TOML type shorthand snippets (bool? / string[]? / …) in Markdown ```toml
;; blocks and in conf-toml-mode / toml-ts-mode.
;;
;;   bool?     -> { type = "bool", optional = true }
;;   bool[]    -> { type = "list", of = "bool" }
;;   bool[]?   -> { type = "list", of = "bool", optional = true }
;;   (same for string, int, float)
;;
;; Trigger with TAB (yas-expand) after typing the key.
;; ---------------------------------------------------------------------------
(defun +toml-md-fence-lang-at-point ()
  "Return language of the enclosing fenced code block, or nil.
Uses markdown-mode text properties when available, else scans fences."
  (or
   ;; Prefer markdown-mode's own detection (needs font-lock/props).
   (when (and (fboundp 'markdown-code-block-at-point-p)
              (markdown-code-block-at-point-p)
              (fboundp 'markdown-code-block-lang))
     (save-excursion (markdown-code-block-lang)))
   ;; Fallback: walk upward looking for ```lang / ~~~lang.
   (save-excursion
     (let ((origin (point))
           (found nil))
       (goto-char (point-min))
       (while (and (not found)
                   (re-search-forward
                    (rx line-start (* blank)
                        (group (or "```" "~~~"))
                        (* blank)
                        (group (* (not (any "\n")))))
                    origin t))
         (let* ((fence (match-string-no-properties 1))
                (info  (string-trim (match-string-no-properties 2)))
                (open-end (match-end 0))
                (close-re (concat "^[ \t]*" (regexp-quote fence) "[ \t]*$")))
           (save-excursion
             (goto-char open-end)
             (when (and (re-search-forward close-re nil t)
                        (<= origin (match-beginning 0))
                        (>= origin open-end))
               ;; info may be "toml" or "toml title=..." — take first token
               (setq found (car (split-string info "[ \t]+" t)))))))
       found))))

(defun +toml-md-in-toml-block-p ()
  "Non-nil when point is inside a fenced Markdown code block tagged toml."
  (when (derived-mode-p 'markdown-mode)
    (let ((lang (+toml-md-fence-lang-at-point)))
      (and lang (string-equal-ignore-case lang "toml")))))

(defun +toml-type-snippet-defs (&optional condition)
  "Build yasnippet defs for TOML type shorthands.
CONDITION is a Lisp form evaluated at expand time (or nil)."
  (cl-loop for type in '("bool" "string" "int" "float")
           nconc
           (cl-loop for (suffix template-fmt name-fmt uuid-sfx) in
                    `(("?"  "{ type = \"%s\", optional = true }"
                       "%s optional" "opt")
                      ("[]" "{ type = \"list\", of = \"%s\" }"
                       "%s list" "list")
                      ("[]?" "{ type = \"list\", of = \"%s\", optional = true }"
                       "%s optional list" "list-opt"))
                    collect
                    ;; (KEY TEMPLATE NAME CONDITION GROUP … UUID)
                    (list (concat type suffix)
                          (format template-fmt type)
                          (format name-fmt type)
                          condition
                          '("toml-types") ; list, as after yas split-string on "#"
                          nil nil nil
                          (format "toml-type-%s-%s" type uuid-sfx)))))

(after! yasnippet
  ;; Markdown: only expand inside ```toml fences.
  (yas-define-snippets 'markdown-mode
                       (+toml-type-snippet-defs '(+toml-md-in-toml-block-p)))
  ;; Native TOML major modes.
  (yas-define-snippets 'conf-toml-mode
                       (+toml-type-snippet-defs))
  (when (fboundp 'toml-ts-mode)
    (yas-define-snippets 'toml-ts-mode
                         (+toml-type-snippet-defs))))

(use-package! reason-mode
  :mode "\\.re[i]?\\'"
  :hook (reason-mode . eglot-ensure))

(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))

;; ---------------------------------------------------------------------------
;; Minuet — LLM ghost-text completion (docs + code)
;; API key: OPENROUTER_API_KEY (env or ~/.config/emacs/.local/env via `doom env`).
;; Manual: M-i  |  accept M-a  |  dismiss M-e  |  cycle M-n / M-p
;; ---------------------------------------------------------------------------
(defun +minuet-openrouter-api-key ()
  "Return OpenRouter API key for Minuet.
Prefers process env; falls back to scraping interactive bashrc export
(GUI Emacs / systemd daemon often never sees vars only set in interactive shells).
Always trims whitespace — a leading newline breaks plz/curl config parsing."
  (let ((key
         (or (let ((k (getenv "OPENROUTER_API_KEY")))
               (and k (not (string-empty-p (string-trim k))) k))
             (when-let* ((bashrc (expand-file-name "~/.bashrc"))
                         ((file-readable-p bashrc))
                         (line (with-temp-buffer
                                 (insert-file-contents bashrc)
                                 (goto-char (point-min))
                                 (when (re-search-forward
                                        (rx bol (* space) "export" (+ space)
                                            "OPENROUTER_API_KEY="
                                            (or (seq ?\" (group (*? anychar)) ?\")
                                                (seq ?\' (group (*? anychar)) ?\')
                                                (group (+ (not (any space ?#)))))
                                            (? (* space) (? ?# (* nonl)))
                                            eol)
                                        nil t)
                                   (or (match-string 1)
                                       (match-string 2)
                                       (match-string 3))))))
               line))))
    (when key
      (setq key (string-trim key))
      (setenv "OPENROUTER_API_KEY" key)
      key)))

(use-package! minuet
  :bind (("M-i" . minuet-show-suggestion)
         :map minuet-active-mode-map
         ("M-a" . minuet-accept-suggestion)
         ("M-e" . minuet-dismiss-suggestion)
         ("M-n" . minuet-next-suggestion)
         ("M-p" . minuet-previous-suggestion))
  :hook (minuet-active-mode . evil-normalize-keymaps)
  :config
  (setq minuet-provider 'openai-compatible
        minuet-n-completions 1
        minuet-request-timeout 2.5
        minuet-auto-suggestion-debounce-delay 0.6
        minuet-auto-suggestion-throttle-delay 1.5
        minuet-context-window 8000)
  (plist-put minuet-openai-compatible-options
             :end-point "https://openrouter.ai/api/v1/chat/completions")
  (plist-put minuet-openai-compatible-options :api-key #'+minuet-openrouter-api-key)
  (plist-put minuet-openai-compatible-options
             :model "google/gemini-3-flash-preview")
  (minuet-set-optional-options minuet-openai-compatible-options :max_tokens 120))

(after! dired
  (setq dired-listing-switches "-alh --group-directories-first")
  (setq dired-use-ls-dired t))

(add-hook! 'dired-mode-hook
  (setq dired-actual-switches "-alh --group-directories-first"))
