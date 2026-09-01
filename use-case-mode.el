;;; use-case-mode.el --- Font-lock for IDesign use-case diagrams -*- lexical-binding: t; -*-
;;
;; Major mode (and optional minor mode) highlighting IDesign activity-diagram
;; tokens.  Intended for fenced Markdown blocks:
;;
;;   ```use-case
;;   Login with password
;;
;;   (START user clicks login)
;;   [Action] # note
;;   {GOTO (START)}
;;   {GOTO [Action]}
;;   (END)
;;   ```
;;
;; Markdown native fontification picks this up via `markdown-code-lang-modes'
;; (see config.el).  Enable `use-case-minor-mode' manually for other buffers
;; (e.g. TOML comments).

;;; Commentary:

;; Token faces:
;;   title (1st non-blank line)  use-case-title-face
;;   (START …) / (START)         use-case-start-face
;;   (END …) / (END)             type / string
;;   [Action]                    use-case-action-face    (blue)
;;   <condition?>                use-case-decision-face  (magenta)
;;   <condition>                 use-case-condition-face (orange)
;;   <_>                         warning  (else/default)
;;   |                           builtin  (fork, first non-ws on line)
;;   {GOTO [Name]}               use-case-goto-face
;;   {GOTO (START|END …)}        use-case-goto-face
;;   # comment                   comment
;;   ->                          operator

;;; Code:

(require 'rx)

(defgroup use-case nil
  "Font-lock for IDesign use-case activity diagrams."
  :group 'faces
  :prefix "use-case-")

;; Explicit colors: doom-one-light maps several font-lock faces to the
;; magenta family, so inherited faces often look identical.
(defface use-case-title-face
  '((((background light)) :foreground "#986801" :weight bold) ; gold/brown
    (((background dark))  :foreground "#ecbe7b" :weight bold)
    (t :inherit font-lock-doc-face :weight bold))
  "Face for the use-case title (first non-blank line of the diagram)."
  :group 'use-case)

(defface use-case-action-face
  '((((background light)) :foreground "#4078f2" :weight semi-bold) ; blue
    (((background dark))  :foreground "#51afef" :weight semi-bold)
    (t :inherit font-lock-function-name-face))
  "Face for [Action] tokens (blue, distinct from guards)."
  :group 'use-case)

(defface use-case-condition-face
  '((((background light)) :foreground "#da8548" :weight semi-bold) ; orange
    (((background dark))  :foreground "#da8548" :weight semi-bold)
    (t :inherit font-lock-constant-face))
  "Face for <condition> guard tokens (orange, distinct from actions)."
  :group 'use-case)

(defface use-case-decision-face
  '((((background light)) :foreground "#a626a4" :weight semi-bold) ; magenta
    (((background dark))  :foreground "#c678dd" :weight semi-bold)
    (t :inherit font-lock-keyword-face))
  "Face for <condition?> decision tokens (magenta)."
  :group 'use-case)

(defface use-case-goto-face
  '((((background light)) :foreground "#0184bc" :weight bold) ; cyan
    (((background dark))  :foreground "#46d9ff" :weight bold)
    (t :inherit font-lock-preprocessor-face))
  "Face for {GOTO …} jumps (cyan)."
  :group 'use-case)

(defface use-case-start-face
  '((((background light)) :foreground "#50a14f" :weight bold) ; green
    (((background dark))  :foreground "#98be65" :weight bold)
    (t :inherit font-lock-builtin-face :weight bold))
  "Face for (START) / (START trigger…) entry points."
  :group 'use-case)

(defun use-case--match-title (limit)
  "Font-lock matcher: first non-blank line of the buffer (use-case title).
LIMIT is the search bound from `font-lock-keywords'."
  (let ((origin (point))
        matched)
    (save-excursion
      (goto-char (point-min))
      (while (and (not (eobp))
                  (looking-at-p (rx line-start (* blank) line-end)))
        (forward-line 1))
      (when (and (not (eobp))
                 (>= (point) origin)
                 (< (point) limit)
                 (looking-at (rx line-start (* blank)
                                 (group (+ (not (any "\n"))))
                                 (* blank) line-end)))
        (let ((text (string-trim (match-string 1))))
          ;; Skip lines that are already diagram tokens.
          (unless (string-match-p
                   (rx bos (or (seq "(" (or "START" "END"))
                               (seq "[" (+ (not (any "]\n"))) "]")
                               (seq "<" (+ (not (any "<>\n"))) ">")
                               (seq "{GOTO")
                               "|")
                           eos)
                   text)
            (setq matched (match-data t))))))
    (when matched
      (set-match-data matched)
      (goto-char (match-end 0))
      t)))

(defconst use-case-font-lock-keywords
  `(
    ;; Title — first non-blank line that isn't already a diagram token.
    (use-case--match-title (1 'use-case-title-face t))

    ;; (START) or (START trigger description)
    (,(rx (group "(START")
          (? (+ space) (group (+ (not (any ")\n")))))
          (group ")"))
     (1 'use-case-start-face)
     (2 'font-lock-string-face nil t) ; optional trigger text
     (3 'use-case-start-face))

    ;; (END) or (END label…)
    (,(rx (group "(END")
          (? (+ space) (group (+ (not (any ")\n")))))
          (group ")"))
     (1 'font-lock-type-face)
     (2 'font-lock-string-face nil t) ; optional label
     (3 'font-lock-type-face))

    ;; {GOTO [Name]} or {GOTO (START…)} / {GOTO (END…)}
    ;; After START/END so the whole form keeps the goto face.
    (,(rx "{GOTO" (+ space)
          (or (seq "[" (+ (not (any "]\n"))) "]")
              (seq "(" (or "START" "END")
                   (? (+ space) (+ (not (any ")\n"))))
                   ")"))
          "}")
     (0 'use-case-goto-face t))

    ;; Line comments: # … (not inside tokens — best-effort from # to EOL)
    (,(rx (group "#" (* nonl)))
     (1 'font-lock-comment-face t))

    ;; [Action] — no override so {GOTO [Name]} keeps goto face
    (,(rx "[" (+ (not (any "]\n"))) "]")
     (0 'use-case-action-face))

    ;; <_> else / default (before general <...>)
    (,(rx "<_>")
     (0 'font-lock-warning-face))

    ;; <condition?> decision
    (,(rx "<" (+ (not (any "<>\n"))) "?>")
     (0 'use-case-decision-face))

    ;; <condition> guard (no ?)
    (,(rx "<" (+ (not (any "<>?\n"))) ">")
     (0 'use-case-condition-face))

    ;; | fork — only first non-whitespace on the line
    (,(rx line-start (* blank) (group "|"))
     (1 'font-lock-builtin-face))

    ;; -> synchronous call
    (,(rx "->")
     (0 'font-lock-operator-face)))
  "Font-lock keywords for IDesign use-case diagram tokens.")

;;;###autoload
(define-derived-mode use-case-mode prog-mode "Use-Case"
  "Major mode for IDesign use-case activity diagrams.

Used by `markdown-mode' native code-block fontification for
fenced blocks tagged `use-case'."
  :group 'use-case
  ;; Quotes appear inside [actions] (e.g. paths); do not treat as strings.
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\" "." st)
    (modify-syntax-entry ?\' "." st)
    (modify-syntax-entry ?# "<" st)
    (modify-syntax-entry ?\n ">" st)
    (set-syntax-table st))
  (setq font-lock-defaults '(use-case-font-lock-keywords nil nil nil nil))
  (setq-local comment-start "# ")
  (setq-local comment-end ""))

;;;###autoload
(define-minor-mode use-case-minor-mode
  "Minor mode highlighting IDesign use-case diagram tokens.

Useful outside Markdown (e.g. diagrams in TOML `# ' comments)."
  :lighter " UC"
  :group 'use-case
  (if use-case-minor-mode
      (font-lock-add-keywords nil use-case-font-lock-keywords 'append)
    (font-lock-remove-keywords nil use-case-font-lock-keywords))
  (when (fboundp 'font-lock-flush)
    (font-lock-flush)))

;;;###autoload
(defun use-case-mode-enable-in-markdown ()
  "Register use-case with markdown native code-block fontification."
  (setq-local markdown-fontify-code-blocks-natively t)
  (when (boundp 'markdown-code-lang-modes)
    (unless (assoc "use-case" markdown-code-lang-modes)
      (setq-local markdown-code-lang-modes
                  (cons '("use-case" . use-case-mode)
                        markdown-code-lang-modes)))))

(provide 'use-case-mode)
;;; use-case-mode.el ends here
