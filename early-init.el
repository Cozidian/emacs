;; -*- lexical-binding: t; -*-

;; Make startup faster by reducing the frequency of garbage collection. This will be set back when startup finishes.
;; We also increase Read Process Output Max so Emacs can read more data.
;; Disable package.el at startup; Elpaca manages packages.
(setq package-enable-at-startup nil)

;; Ensure GUI Emacs on macOS can find Homebrew tools (e.g. pkg-config for jinx build).
(when (eq system-type 'darwin)
  (dolist (dir '("/opt/homebrew/bin" "/opt/homebrew/sbin" "/usr/local/bin" "/usr/local/sbin"))
    (when (file-directory-p dir)
      (add-to-list 'exec-path dir)
      (setenv "PATH" (concat dir path-separator (getenv "PATH"))))))

;; Set garbage collector (from doom emacs)
;; About 0.02 faster
(setq gc-cons-threshold (* 1024 1024 128)  ;; 128mb
      gc-cons-percentage 1.0) ;; Disable the dynamic percentage trigger to ensure GC frequency is fixed.

;; Runtime performance
;; Dial the GC threshold back down so that garbage collection happens more frequently but in less time.
;; Make gc pauses faster by decreasing the threshold.
;; About 0.02 faster
(add-hook 'emacs-startup-hook (lambda ()
                                (setq gc-cons-threshold (* 1024 1024 2) ;; 2mb
                                      gc-cons-percentage 0.2)))

;; Increase the amount of data which Emacs reads from the process
(setq read-process-output-max (* 1024 1024)) ;; 1mb

;; Unset file-name-handler-alist
;; About 0.07 faster
(defvar last-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'after-init-hook
          (lambda ()
            (setq file-name-handler-alist last-file-name-handler-alist)))

;; Fix white flash on startup
;; Don't do it when using daemon or terminal, because it messes up the background color.
;; (unless (or (daemonp) (not initial-window-system))
;;   (setq default-frame-alist '(
;;                               (foreground-color . "white")
;;                               (background-color . "#181818"))))

;; Disable UI elements before UI initialization.
;; For faster startup times. It gives 0.05 sec.
(setq menu-bar-mode nil)         ;; Disable the menu bar
(setq tool-bar-mode nil)         ;; Disable the tool bar
(push '(vertical-scroll-bars) default-frame-alist) ;; Disable the scroll bar

;;; FONTS
;; Font settings live in init.org under Appearance -> Fonts.

(prefer-coding-system 'utf-8)

;; Check if init.el exists, if not, tangle init.org to produce init.el
(let ((init-el (expand-file-name "init.el" user-emacs-directory))
      (init-org (expand-file-name "init.org" user-emacs-directory)))
  (unless (file-exists-p init-el)
    (when (file-exists-p init-org)
      (require 'org)
      (org-babel-tangle-file init-org init-el)
      (message "Tangling %s to create missing %s" init-org init-el))))
