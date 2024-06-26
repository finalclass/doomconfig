(defun fc-get-relative-file-path ()
  (if (buffer-file-name)
      (fc-get-regular-file-path)
    (fc-get-git-preview-file-path)))

(defun fc-get-git-preview-file-path ()
  (substring (car (split-string (buffer-name) "~")) 0 -1))

(defun fc-get-regular-file-path ()
  (let (
	(root-dir (vc-root-dir))
	(abs-path (file-truename (buffer-file-name)))
	)
    (file-relative-name abs-path root-dir)))

(defun fc-line-or-selected-lines ()
  (if (region-active-p)
      (fc-get-region-line-numbers)
    (concat "L" (number-to-string (line-number-at-pos)))))

(defun fc-get-region-line-numbers ()
  (concat
   "L"
   (number-to-string (line-number-at-pos (region-beginning)))
   "-L"
   (number-to-string (line-number-at-pos (region-end)))))


(defun fc-get-project-name()
  (car
   (split-string
    (car
     (last
      (split-string
       (shell-command-to-string "git config --get remote.origin.url")
       "/")))
    "\\.git")))

(defun fc-get-current-git-commit ()
  (substring (shell-command-to-string "git rev-parse HEAD") 0 -1))

(defun fc-get-gitea-url ()
  (concat
   "https://gitea.7willows.com/7willows/"
   (fc-get-project-name)
   "/src/commit/"
   (fc-get-current-git-commit)
   "/"
   (fc-get-relative-file-path)
   "#"
   (fc-line-or-selected-lines)))

(defun fc-kill-gitea-address ()
  (interactive)
  (message
   (kill-new
    (fc-get-gitea-url))))

(map! :leader
      "g 0" #'fc-kill-gitea-address)
