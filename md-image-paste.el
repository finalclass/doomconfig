;;; md-image-paste.el -*- lexical-binding: t; -*-
;; Paste system-clipboard images into Markdown buffers.
;; p / P (normal) and C-v (insert) fall back to normal paste when the
;; clipboard holds no image. M-x md-image-paste-paste works in any buffer
;; visiting a file. Sources: raw image (screenshots, browser copy) and
;; text/uri-list (multiple files copied in a file manager).

(require 'cl-lib)
(require 'url-util)

(defvar md-image-paste-name-prefix "img")
(defvar md-image-paste-image-extensions
  '("png" "jpg" "jpeg" "webp" "gif" "bmp" "svg" "avif"))

(defconst md-image-paste--mime-extensions
  '(("image/png" . "png")
    ("image/jpeg" . "jpg")
    ("image/webp" . "webp")
    ("image/gif" . "gif")
    ("image/bmp" . "bmp")
    ("image/avif" . "avif")
    ("image/svg+xml" . "svg")))

(defun md-image-paste--wayland-display ()
  "Ensure WAYLAND_DISPLAY is set; discover a socket under /run/user/UID."
  (or (getenv "WAYLAND_DISPLAY")
      (let ((dir (expand-file-name (number-to-string (user-uid)) "/run/user")))
        (when (file-directory-p dir)
          (let ((socket (car (directory-files dir nil "^wayland-"))))
            (when socket
              (setenv "WAYLAND_DISPLAY" socket)
              socket))))))

(defun md-image-paste--clipboard-types ()
  (and (executable-find "wl-paste")
       (md-image-paste--wayland-display)
       (ignore-errors
         (with-temp-buffer
           (and (zerop (call-process "wl-paste" nil t nil "--list-types"))
                (split-string (buffer-string) "[\n\r]+" t))))))

(defun md-image-paste--clipboard-image-mime ()
  "Return (MIME . EXT) when the clipboard holds raw image data."
  (let ((types (md-image-paste--clipboard-types)))
    (cl-some (lambda (pair) (and (member (car pair) types) pair))
             md-image-paste--mime-extensions)))

(defun md-image-paste--unique-path (dir base ext)
  (let ((path (expand-file-name (concat base "." ext) dir))
        (n 2))
    (while (file-exists-p path)
      (setq path (expand-file-name (format "%s-%d.%s" base n ext) dir)
            n (1+ n)))
    path))

(defun md-image-paste--save-clipboard-image (dir)
  "Write the raw clipboard image into DIR; return its path or nil."
  (let ((mime-ext (md-image-paste--clipboard-image-mime)))
    (when mime-ext
      (let* ((base (concat md-image-paste-name-prefix
                           "-" (format-time-string "%Y%m%d-%H%M%S")))
             (path (md-image-paste--unique-path dir base (cdr mime-ext))))
        (if (and (zerop (call-process "wl-paste" nil (list :file path)
                                      nil "--type" (car mime-ext)))
                 (file-exists-p path)
                 (> (file-attribute-size (file-attributes path)) 0))
            path
          (ignore-errors (delete-file path))
          nil)))))

(defun md-image-paste--clipboard-uri-images ()
  "Local image file paths from a text/uri-list clipboard entry."
  (and (member "text/uri-list" (md-image-paste--clipboard-types))
       (ignore-errors
         (with-temp-buffer
           (and (zerop (call-process "wl-paste" nil t nil
                                     "--type" "text/uri-list"))
                (progn
                  (goto-char (point-min))
                  (cl-loop while (re-search-forward "[^ \t\r\n]+" nil t)
                           for uri = (match-string 0)
                           for path = (and (string-prefix-p "file://" uri)
                                           (url-unhex-string
                                            (substring uri (length "file://"))))
                           when (and path
                                     (file-readable-p path)
                                     (member (downcase
                                              (or (file-name-extension path) ""))
                                             md-image-paste-image-extensions))
                           collect path)))))))

(defun md-image-paste--copy-clipboard-files (dir)
  "Copy clipboard uri-list images into DIR; return copied paths."
  (cl-loop for src in (md-image-paste--clipboard-uri-images)
           for dest = (md-image-paste--unique-path
                       dir (file-name-base src)
                       (or (file-name-extension src) "png"))
           do (copy-file src dest)
           collect dest))

(defun md-image-paste-paste ()
  "Paste clipboard image(s) next to the visited file and insert links.
Each image is saved into the directory of the current file and a
markdown tag `![](name.png)` is inserted at point. Return the list of
written paths, or nil when the clipboard holds no image."
  (interactive)
  (unless (buffer-file-name)
    (user-error "Buffer does not visit a file — nowhere to save images"))
  (let* ((dir (file-name-directory (buffer-file-name)))
         (paths (or (md-image-paste--copy-clipboard-files dir)
                    (let ((p (md-image-paste--save-clipboard-image dir)))
                      (and p (list p))))))
    (when paths
      (insert (string-join
               (mapcar (lambda (p)
                         (format "![](%s)" (file-name-nondirectory p)))
                       paths)
               "\n"))
      (message "md-image-paste: %s"
               (string-join (mapcar #'file-name-nondirectory paths) ", ")))
    paths))

(defun md-image-paste-or-yank (&optional _arg)
  (interactive "*P")
  (or (and (buffer-file-name) (md-image-paste-paste))
      (yank)))

(defun md-image-paste-or-evil-paste-after (&optional arg)
  (interactive "*P")
  (or (and (buffer-file-name) (md-image-paste-paste))
      (evil-paste-after arg)))

(defun md-image-paste-or-evil-paste-before (&optional arg)
  (interactive "*P")
  (or (and (buffer-file-name) (md-image-paste-paste))
      (evil-paste-before arg)))

(defun md-image-paste-or-evil-clipboard (&optional _arg)
  (interactive "*")
  (or (and (buffer-file-name) (md-image-paste-paste))
      (evil-paste-from-register ?+)))

(with-eval-after-load 'markdown-mode
  (when (fboundp 'evil-define-key)
    (evil-define-key 'normal markdown-mode-map
      "p" #'md-image-paste-or-evil-paste-after
      "P" #'md-image-paste-or-evil-paste-before)
    (evil-define-key 'insert markdown-mode-map
      (kbd "C-v") #'md-image-paste-or-evil-clipboard)))

(provide 'md-image-paste)
;;; md-image-paste.el ends here
