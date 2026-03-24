;; -*- lexical-binding: t; -*-

(defun start/org-babel-tangle-config ()
  "Automatically tangle our init.org config file when we save it. Credit to Emacs From Scratch for this one!"
  (interactive)
  (when (string-equal (file-name-directory (buffer-file-name))
                      (expand-file-name user-emacs-directory))
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle)
      )))

(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'start/org-babel-tangle-config)))

(defun start/display-startup-time ()
  (interactive)
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                    (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'emacs-startup-hook #'start/display-startup-time)

(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil))
      (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
  (require 'elpaca-use-package)
  (elpaca-use-package-mode))
(elpaca-wait)
(setq use-package-always-ensure t)

(use-package async
  :defer
  :custom
  (dired-async-mode t))

(use-package emacs
  :ensure nil
  :custom
  ;; Still needed for terminals
  (menu-bar-mode nil)         ;; Disable the menu bar
  (scroll-bar-mode nil)       ;; Disable the scroll bar
  (tool-bar-mode nil)         ;; Disable the tool bar

  (inhibit-startup-screen t)  ;; Disable welcome screen

  (delete-selection-mode t)   ;; Select text and delete it by typing.
  (electric-indent-mode nil)  ;; Turn off the weird indenting that Emacs does by default.
  (electric-pair-mode t)      ;; Turns on automatic parens pairing

  (blink-cursor-mode nil)     ;; Don't blink cursor
  (global-auto-revert-mode t) ;; Automatically reload file and show changes if the file has changed
  (use-short-answers t)   ;; Since Emacs 29, `yes-or-no-p' will use `y-or-n-p'

  (dired-kill-when-opening-new-dired-buffer t) ;; Dired don't create new buffer
  (add-hook 'dired-mode-hook #'dired-hide-details-mode)
  (recentf-mode t) ;; Enable recent file mode
  ;;(context-menu-mode t) ;; Right-click menu

  ;;(global-visual-line-mode t)           ;; Enable line wrapping (NOTE: breaks vundo)
  (global-display-line-numbers-mode t)  ;; Display line numbers
  (display-line-numbers-type 'relative) ;; Relative line numbers
  (global-hl-line-mode t)               ;; Highlight current line

  (native-comp-async-report-warnings-errors 'silent) ;; Don't show native comp errors
  (warning-minimum-level :error) ;; Only show errors in warnings buffer

  (cursor-in-non-selected-windows nil) ;; Hide cursor in inactive windows
  (use-dialog-box nil)                 ;; No native OS dialogs
  (frame-title-format "%b")            ;; Just buffer name in title bar

  (mouse-wheel-progressive-speed nil) ;; Disable progressive speed when scrolling
  (scroll-conservatively 3)           ;; For ultra-scroll
  (scroll-margin 0)                   ;; For ultra-scroll

  (indent-tabs-mode nil) ;; Only use spaces for indentation
  (tab-width 4)
  (sgml-basic-offset 4) ;; Set Html mode indentation to 4
  (c-ts-mode-indent-offset 4) ;; Fix weird indentation in c-ts (C, C++)
  (go-ts-mode-indent-offset 4) ;; Fix weird indentation in go-ts

  ;; (display-fill-column-indicator-column 80) ;; Set line length indicator to 80 characters
  (whitespace-style '(face tabs tab-mark trailing))

  (make-backup-files nil) ;; Stop creating ~ backup files
  (auto-save-default nil) ;; Stop creating # auto save files
  (delete-by-moving-to-trash t)
  ;; macOS + Norwegian/intl keyboard:
  ;; left Option types symbols like {}[]|, right Option acts as Meta (M-...).
  (ns-option-modifier nil)
  (ns-right-option-modifier 'meta)
  (mac-option-modifier nil)
  (mac-right-option-modifier 'meta)
  :hook
  (prog-mode . hs-minor-mode) ;; Enable folding hide/show globally
  ;; (prog-mode . display-fill-column-indicator-mode) ;; Display line length indicator
  (prog-mode . whitespace-mode)
  :config
  ;; Move customization variables to a separate file and load it, avoid filling up init.el with unnecessary variables
  (setq custom-file (locate-user-emacs-file "custom-vars.el"))
  (load custom-file 'noerror 'nomessage)
  (winner-mode 1)                        ;; Enable window layout undo/redo
  (global-unset-key (kbd "C-z"))         ;; Prevent accidental suspend
  :bind (
         ([escape] . keyboard-escape-quit) ;; Makes Escape quit prompts (Minibuffer Escape)
         ;; Zooming In/Out
         ("C-+" . text-scale-increase)
         ("C--" . text-scale-decrease)
         ("<C-wheel-up>" . text-scale-increase)
         ("<C-wheel-down>" . text-scale-decrease)
         ))

(use-package evil
  :hook (elpaca-after-init . evil-mode)
  :init
  (evil-mode)
  :config
  (evil-set-initial-state 'eat-mode 'insert) ;; Set initial state in eat terminal to insert mode
  ;; (global-set-key [C-backspace] 'evil-delete-backward-word) ;; Make C-backspace less agressive
  :custom
  (evil-want-keybinding nil)    ;; Disable evil bindings in other modes (It's not consistent and not good)
  (evil-want-C-u-scroll t)      ;; Set C-u to scroll up
  (evil-want-C-i-jump nil)      ;; Disables C-i jump
  (evil-undo-system 'undo-redo) ;; C-r to redo
  (evil-want-fine-undo t)
  ;; (evil-respect-visual-line-mode t) ;; Move in wrap lines
  ;; Unmap keys in 'evil-maps. If not done, org-return-follows-link will not work
  :bind (:map evil-motion-state-map
              ("SPC" . nil)
              ("RET" . nil)
              ("TAB" . nil)))
(use-package evil-collection
  :after evil
  :config
  ;; Setting where to use evil-collection)
  (setq evil-collection-mode-list '(dired ibuffer magit corfu consult info bookmark))
  (evil-collection-init))

(use-package evil-commentary
  :after evil
  :config
  (evil-commentary-mode))

(defun start/open-init-file ()
    "Open init.org configuration file"
    (interactive)
    (find-file "~/.config/emacs/init.org"))

  (defun start/find-org-file ()
    "Fuzzy find a file in ~/org."
    (interactive)
    (consult-fd "~/org"))

  (defun start/reload-config()
    "Reload Emacs config"
    (interactive)
    (load-file "~/.config/emacs/init.el"))

  (defun start/copy-file-path ()
    "Copy the current buffer file path to the kill ring."
    (interactive)
    (if-let ((path (buffer-file-name)))
        (progn
          (kill-new (file-truename path))
          (message "Copied path: %s" (file-truename path)))
      (message "Current buffer is not visiting a file.")))

  (defun start/split-window-below-and-focus ()
    "Split the current window below and move focus to it."
    (interactive)
    (split-window-below)
    (windmove-down))

  (defun start/split-window-right-and-focus ()
    "Split the current window right and move focus to it."
    (interactive)
    (split-window-right)
    (windmove-right))

  (defvar start/font-scale-repeat-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "+") #'start/font-scale-increase)
      (define-key map (kbd "-") #'start/font-scale-decrease)
      (define-key map (kbd "=") #'start/font-scale-reset)
      map)
    "Transient keymap used to repeat font scaling commands.")

  (defun start/font-scale-increase ()
    "Increase font size and keep font scaling keys active."
    (interactive)
    (text-scale-increase 1)
    (set-transient-map start/font-scale-repeat-map t))

  (defun start/font-scale-decrease ()
    "Decrease font size and keep font scaling keys active."
    (interactive)
    (text-scale-decrease 1)
    (set-transient-map start/font-scale-repeat-map t))

  (defun start/font-scale-reset ()
    "Reset font size and keep font scaling keys active."
    (interactive)
    (text-scale-set 0)
    (set-transient-map start/font-scale-repeat-map t))

  (use-package general
    :after (evil) ;; <- evil
    :config
    (general-evil-setup) ;; <- evil
    ;; Set up 'SPC' as the Evil leader key
    (general-create-definer start/leader-keys
      :states '(normal visual motion) ;; <- evil
      :keymaps 'override
      :prefix "SPC"
      :global-prefix "C-SPC") ;; Global fallback from non-evil states

    (start/leader-keys
      "." '(find-file :wk "Find file")
      "," '(embark-act :wk "Embark act")
      "/" '((lambda () (interactive) (consult-ripgrep (projectile-project-root))) :wk "Search project")
      "q" '(:ignore t :wk "Quit")

      ;; Projectile
      "p" '(projectile-command-map :wk "Projectile")
      "s p" '(projectile-discover-projects-in-search-path :wk "Search for projects"))

    (start/leader-keys
      "f" '(:ignore t :wk "Files")
      "f f" '(find-file :wk "Find file")
      "f s" '(save-buffer :wk "Save file")
      "f S" '(write-file :wk "Save file as")
      "f r" '(consult-recent-file :wk "Recent files")
      "f c" '(start/open-init-file :wk "Open config")
      "f d" '(dired-jump :wk "Dired at file")
      "f y" '(start/copy-file-path :wk "Copy file path"))

    (start/leader-keys
      "m" '(:ignore t :wk "Bookmarks & Registers")
      ;; Registers
      "m s" '(consult-register :wk "Consult register")
      "m k" '(jump-to-register :wk "Jump to register")
      "m e" '(point-to-register :wk "Point to register")
      ;; Bookmarks
      "m a" '(bookmark-set :wk "Bookmark Set")
      "m d" '(bookmark-jump :wk "Bookmark Jump")
      "m r" '(bookmark-delete :wk "Bookmark Delete")
      "m R" '(bookmark-delete-all :wk "Bookmark Delete All")
      "m l" '(bookmark-bmenu-list :wk "Bookmark bmenu list")
      "m c" '(consult-bookmark :wk "Consult Bookmark"))

    (start/leader-keys
      "s" '(:ignore t :wk "Search")
      "s r" '(consult-recent-file :wk "Search recent files")
      "s f" '(consult-fd :wk "Search files with fd")
      "s g" '(consult-ripgrep :wk "Search with ripgrep")
      "s l" '(consult-line :wk "Search line")
      "s i" '(consult-imenu :wk "Search Imenu buffer locations") ;; This one is really cool
      "s s" '(start/search-in-file :wk "Search in file (transient)"))

    (start/leader-keys
      "b" '(:ignore t :wk "Buffers & Dired")
      "b b" '(consult-buffer :wk "Switch buffer")
      "b d" '(kill-current-buffer :wk "Kill current buffer")
      "b i" '(ibuffer :wk "Ibuffer")
      "b n" '(next-buffer :wk "Next buffer")
      "b p" '(previous-buffer :wk "Previous buffer")
      "b r" '(revert-buffer :wk "Reload buffer")
      "b v" '(dired :wk "Open dired")
      "b j" '(dired-jump :wk "Dired jump to current"))

    (start/leader-keys
      "o" '(:ignore t :wk "Org")
      "o o" '(start/find-org-file :wk "Find org file")
      "o a" '(org-agenda :wk "Org agenda")
      "o d" '((lambda () (interactive) (dired "~/org")) :wk "Org directory"))

    (start/leader-keys
      "w" '(:ignore t :wk "Windows")
      "w w" '(other-window :wk "Other window")
      "w s" '(split-window-below :wk "Split below")
      "w v" '(split-window-right :wk "Split right")
      "w S" '(start/split-window-below-and-focus :wk "Split below + focus")
      "w V" '(start/split-window-right-and-focus :wk "Split right + focus")
      "w d" '(delete-window :wk "Delete window")
      "w o" '(delete-other-windows :wk "Delete others")
      "w +" '(start/font-scale-increase :wk "Increase font")
      "w -" '(start/font-scale-decrease :wk "Decrease font")
      "w =" '(start/font-scale-reset :wk "Reset font")
      "w h" '(windmove-left :wk "Move left")
      "w j" '(windmove-down :wk "Move down")
      "w k" '(windmove-up :wk "Move up")
      "w l" '(windmove-right :wk "Move right")
      "w H" '(windmove-swap-states-left :wk "Window left")
      "w J" '(windmove-swap-states-down :wk "Window down")
      "w K" '(windmove-swap-states-up :wk "Window up")
      "w L" '(windmove-swap-states-right :wk "Window right"))

    (start/leader-keys
      "c" '(:ignore t :wk "Code")
      "c e" '(eglot-reconnect :wk "Eglot Reconnect")
      "c d" '(eldoc-doc-buffer :wk "Eldoc Buffer")
      "c h" '(eldoc-box-help-at-point :wk "Eldoc Box")
      "c f" '(eglot-format :wk "Eglot Format")
      "c g" '(gptel :wk "GPTel")

      "c l" '(consult-flymake :wk "Consult Flymake")
      "c n" '(flymake-goto-next-error :wk "Flymake next error")
      "c p" '(flymake-goto-prev-error :wk "Flymake previous error")

      "c a" '(eglot-code-actions :wk "Eglot code actions")
      "c r" '(eglot-rename :wk "Eglot Rename")
      "c i" '(xref-find-definitions :wk "Find definition")
      "c s" '(xref-find-references :wk "Find references"))

    (start/leader-keys
      "e" '(:ignore t :wk "Elisp")
      "e b" '(eval-buffer :wk "Evaluate elisp in buffer")
      "e r" '(eval-region :wk "Evaluate elisp in region"))

    (start/leader-keys
      "g" '(:ignore t :wk "Git")
      "g s" '(magit-status :wk "Magit status")
      "g b" '(magit-blame  :wk "Magit blame")
      "g l" '(magit-log-current :wk "Magit log")
      "g r" '(start/ai-review-staged :wk "AI review staged")
      "g R" '(start/ai-review-unstaged :wk "AI review unstaged")
      "g B" '(start/ai-review-branch :wk "AI review branch"))

    (start/leader-keys
      "r" '(:ignore t :wk "Reload & Packages") ;; To get more help use C-h commands (describe variable, function, etc.)
      ;; Mason.el
      "r m" '(mason-manager :wk "Mason manager")
      "r i" '(mason-install :wk "Mason install")
      ;; Elpaca
      "r p" '(elpaca-manager :wk "Elpaca manager")
      "r f" '(elpaca-fetch-all :wk "Elpaca fetch updates")
      "r g" '(elpaca-merge-all :wk "Elpaca merge updates")
      "r u" '(elpaca-update-all :wk "Elpaca update all")
      "r l" '(elpaca-log :wk "Elpaca log")

      "r r" '(start/reload-config :wk "Reload Emacs config"))

(start/leader-keys
  "q" '(:ignore t :wk "Quit")
  "q q" '(save-buffers-kill-emacs :wk "Quit Emacs")
  "q r" '(start/reload-config :wk "Reload config"))

    (start/leader-keys
      "t" '(:ignore t :wk "Toggle")
      "t e" '(eat :wk "Eat terminal")
      "t v" '(vterm :wk "Vterm")
      "t V" '(multi-vterm :wk "Multi-vterm")
      "t s" '(start/toggle-spelling :wk "Toggle spelling")
      "t t" '(visual-line-mode :wk "Toggle truncated lines (wrap)")
      "t l" '(display-line-numbers-mode :wk "Toggle line numbers")
      "t p" '(org-tree-slide-mode :wk "Presentation mode"))

    (tab-bar-mode 1)

    (start/leader-keys
      "TAB"     '(:ignore t :wk "Tabs")
      "TAB TAB" '(tab-bar-select-tab-by-name    :wk "Switch tab by name")
      "TAB n"   '(tab-bar-new-tab               :wk "New tab")
      "TAB d"   '(tab-bar-close-tab             :wk "Close tab")
      "TAB ["   '(tab-bar-switch-to-prev-tab    :wk "Previous tab")
      "TAB ]"   '(tab-bar-switch-to-next-tab    :wk "Next tab")
      "TAB 1"   '((lambda () (interactive) (tab-bar-select-tab 1)) :wk "Tab 1")
      "TAB 2"   '((lambda () (interactive) (tab-bar-select-tab 2)) :wk "Tab 2")
      "TAB 3"   '((lambda () (interactive) (tab-bar-select-tab 3)) :wk "Tab 3")
      "TAB 4"   '((lambda () (interactive) (tab-bar-select-tab 4)) :wk "Tab 4")
      "TAB 5"   '((lambda () (interactive) (tab-bar-select-tab 5)) :wk "Tab 5")
      "TAB 6"   '((lambda () (interactive) (tab-bar-select-tab 6)) :wk "Tab 6")
      "TAB 7"   '((lambda () (interactive) (tab-bar-select-tab 7)) :wk "Tab 7")
      "TAB 8"   '((lambda () (interactive) (tab-bar-select-tab 8)) :wk "Tab 8")
      "TAB 9"   '((lambda () (interactive) (tab-bar-select-tab 9)) :wk "Tab 9"))
    )

  ;; Fix general.el leader key not working instantly in messages buffer with evil mode
  (use-package emacs
    :ensure nil
    :after (evil general)
    :hook (elpaca-after-init
           . (lambda ()
               (when-let ((messages-buffer (get-buffer "*Messages*")))
                 (with-current-buffer messages-buffer
                   (evil-normalize-keymaps))))))

(defvar start/font-family "Cascadia Mono")
(defvar start/font-size 160) ;; 120 = 12pt
(defvar start/font-weight 'medium)
(defvar start/font-line-spacing 0.12)

(defun start/apply-fonts (&optional frame)
  "Apply base font settings to FRAME or current frame."
  (with-selected-frame (or frame (selected-frame))
    (when (display-graphic-p)
      (set-face-attribute 'default nil
                          :family start/font-family
                          :height start/font-size
                          :weight start/font-weight)))
  (setq-default line-spacing start/font-line-spacing))

;; Apply now and for new frames (important for emacsclient/daemon).
(start/apply-fonts)
(add-hook 'after-make-frame-functions #'start/apply-fonts)

(defvar start/frame-size-ratio 0.80)

(defun start/apply-frame-size (&optional frame)
  "Resize FRAME to `start/frame-size-ratio' of monitor workarea and center it."
  (let ((frame (or frame (selected-frame))))
    (when (display-graphic-p frame)
      (let* ((workarea (and (fboundp 'frame-monitor-attribute)
                            (frame-monitor-attribute 'workarea frame)))
             (wx (or (nth 0 workarea) 0))
             (wy (or (nth 1 workarea) 0))
             (ww (or (nth 2 workarea) (display-pixel-width frame)))
             (wh (or (nth 3 workarea) (display-pixel-height frame)))
             (target-w (floor (* ww start/frame-size-ratio)))
             (target-h (floor (* wh start/frame-size-ratio)))
             (left (+ wx (/ (- ww target-w) 2)))
             (top (+ wy (/ (- wh target-h) 2))))
        (set-frame-parameter frame 'internal-border-width 0) ;; Remove thin border (visible on macOS Monterey+)
        (set-frame-size frame target-w target-h t)
        (set-frame-position frame left top)))))

;; Apply on startup and for new frames (emacsclient/daemon).
(add-hook 'window-setup-hook #'start/apply-frame-size)
(add-hook 'after-make-frame-functions #'start/apply-frame-size)

;; Pixel-perfect frame resizing.
(setq frame-resize-pixelwise t)

;; Remove continuation fringe indicator for a cleaner look.
(setq-default fringe-indicator-alist
              (delq (assq 'continuation fringe-indicator-alist)
                    fringe-indicator-alist))

(use-package gruvbox-theme
  :config
  (setq gruvbox-bold-constructs t)
  (load-theme 'gruvbox-dark-medium t)) ;; We need to add t to trust this package

(add-to-list 'default-frame-alist '(alpha-background . 90)) ;; For all new frames henceforth

;; Transparency in terminal
(defun start/tui-enable-transparency ()
  (unless (display-graphic-p (selected-frame))
    (set-face-background 'default "unspecified-bg" (selected-frame))))

(add-hook 'window-setup-hook 'start/tui-enable-transparency)

(use-package moody
  :config
  (setq x-underline-at-descent-line t)
  (setq-default mode-line-format
                '(" "
                  mode-line-front-space
                  mode-line-buffer-identification
                  " "
                  mode-line-position
                  (vc-mode vc-mode)
                  " " mode-line-modes
                  mode-line-misc-info
                  mode-line-end-spaces))
  (moody-replace-mode-line-buffer-identification)
  (moody-replace-vc-mode))

(use-package minions
  :after moody
  :custom
  (minions-mode-line-lighter "…")
  (minions-mode-line-delimiters '("" . ""))
  :config
  (minions-mode +1))

(use-package nerd-icons :defer)

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package nerd-icons-ibuffer
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

(use-package ultra-scroll
  :ensure (:host github :repo "jdtsmith/ultra-scroll")
  :custom
  (scroll-conservatively 3)
  (scroll-margin 0)
  :config
  (ultra-scroll-mode +1))

(use-package nyan-mode
  :defer 20
  :if (display-graphic-p)
  :custom
  (nyan-bar-length 10)
  :config
  (nyan-mode +1))

(use-package olivetti
  :defer t)

(use-package projectile
  :hook (elpaca-after-init . projectile-mode)
  :config
  (projectile-mode)
  :custom
  ;; (projectile-auto-discover nil) ;; Disable auto search for better startup times ;; Search with a keybind
  (projectile-run-use-comint-mode t) ;; Interactive run dialog when running projects inside emacs (like giving input)
  (projectile-switch-project-action #'projectile-dired) ;; Open dired when switching to a project
  (projectile-project-search-path '("~/projects/" "~/work/" ("~/github" . 1)))) ;; . 1 means only search the first subdirectory level for projects

(use-package eglot
  :ensure nil ;; Don't install eglot because it's now built-in
  :hook ((c-mode c-ts-mode c++-mode c++-ts-mode
                 lua-mode lua-ts-mode
                 python-mode python-ts-mode
                 elixir-mode elixir-ts-mode heex-ts-mode
                 typescript-ts-mode tsx-ts-mode)
         . eglot-ensure)
  :custom
  ;; Good default
  (eglot-events-buffer-size 0) ;; No event buffers (LSP server logs)
  (eglot-autoshutdown t);; Shutdown unused servers.
  (eglot-report-progress nil) ;; Disable LSP server logs (Don't show lsp messages at the bottom, java)
  :config
  ;; Use basedpyright for Python via uv.
  ;; uv will cache the tool after the first run.
  (setf (alist-get '(python-mode python-ts-mode)
                   eglot-server-programs
                   nil nil #'equal)
        '("uv" "tool" "run" "--from" "basedpyright"
          "basedpyright-langserver" "--stdio"))
  ;; Use Expert as Elixir LSP server. See: https://expert-lsp.org/docs/editors#emacs
  (setf (alist-get '(elixir-mode heex-ts-mode elixir-ts-mode)
                   eglot-server-programs
                   nil nil #'equal)
        '("expert" "--stdio")))

(use-package mason
  :hook (elpaca-after-init . mason-ensure))

(use-package eldoc-box
  :commands (eldoc-box-help-at-point))

(use-package sideline-flymake
  :hook (flymake-mode . sideline-mode)
  :custom
  (sideline-flymake-display-mode 'line) ;; Show errors on the current line
  (sideline-backends-right '(sideline-flymake)))

(use-package yasnippet
  :hook (prog-mode . yas-minor-mode))

(use-package yasnippet-snippets :defer)

(defun start/corfu-yas-tab-handler ()
  "Prioritize corfu over yasnippet when yasnippet is active"
  (interactive)
  ;; There is no direct way to get if corfu is currently displayed so we watch the completion index
  (if (> corfu--index -1)
      (corfu-complete)
    (yas-next-field-or-maybe-expand)
    ))
(use-package emacs
  :ensure nil
  :after (yasnippet corfu)
  :bind
  (:map yas-keymap
        ("TAB" . start/corfu-yas-tab-handler)))

(setq treesit-language-source-alist
      '((bash "https://github.com/tree-sitter/tree-sitter-bash")
        (cmake "https://github.com/uyha/tree-sitter-cmake")
        (c "https://github.com/tree-sitter/tree-sitter-c")
        (cpp "https://github.com/tree-sitter/tree-sitter-cpp")
        (css "https://github.com/tree-sitter/tree-sitter-css")
        (elixir "https://github.com/elixir-lang/tree-sitter-elixir")
        (elisp "https://github.com/Wilfred/tree-sitter-elisp")
        (gdscript "https://github.com/PrestonKnopp/tree-sitter-gdscript")
        (go "https://github.com/tree-sitter/tree-sitter-go")
        (gomod "https://github.com/camdencheek/tree-sitter-go-mod")
        (heex "https://github.com/phoenixframework/tree-sitter-heex")
        (html "https://github.com/tree-sitter/tree-sitter-html")
        (hyprlang "https://github.com/tree-sitter-grammars/tree-sitter-hyprlang")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
        (json "https://github.com/tree-sitter/tree-sitter-json")
        (make "https://github.com/alemuller/tree-sitter-make")
        (markdown "https://github.com/ikatyang/tree-sitter-markdown")
        (python "https://github.com/tree-sitter/tree-sitter-python")
        (rust "https://github.com/tree-sitter/tree-sitter-rust")
        (toml "https://github.com/tree-sitter/tree-sitter-toml")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (vue "https://github.com/ikatyang/tree-sitter-vue")
        (yaml "https://github.com/ikatyang/tree-sitter-yaml")))

(defun start/install-treesit-grammars ()
  "Install missing treesitter grammars"
  (interactive)
  (dolist (grammar treesit-language-source-alist)
    (let ((lang (car grammar)))
      (unless (treesit-language-available-p lang)
        (treesit-install-language-grammar lang)))))

;; Run manually when needed: M-x start/install-treesit-grammars
;; Avoid installing grammars at every startup.

;; Optionally, add any additional mode remappings not covered by defaults
(setq major-mode-remap-alist
      '((yaml-mode . yaml-ts-mode)
        (sh-mode . bash-ts-mode)
        (c-mode . c-ts-mode)
        (c++-mode . c++-ts-mode)
        (css-mode . css-ts-mode)
        (elixir-mode . elixir-ts-mode)
        (heex-mode . heex-ts-mode)
        (python-mode . python-ts-mode)
        (mhtml-mode . html-ts-mode)
        (javascript-mode . js-ts-mode)
        (js-json-mode . json-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (conf-toml-mode . toml-ts-mode)
        (gdscript-mode . gdscript-ts-mode)
        ))
(setq treesit-font-lock-level 3)

;; Or if there is no built in mode
(use-package cmake-ts-mode :ensure nil :mode ("CMakeLists\\.txt\\'" "\\.cmake\\'"))
(use-package elixir-ts-mode :ensure nil :mode ("\\.ex\\'" "\\.exs\\'"))
(use-package go-mod-ts-mode :ensure nil :mode "\\.mod\\'")
(use-package heex-ts-mode :ensure nil :mode ("\\.[hl]?eex\\'"))
(use-package lua-ts-mode :ensure nil :mode "\\.lua\\'")
(use-package rust-ts-mode :ensure nil :mode "\\.rs\\'")
(use-package typescript-ts-mode :ensure nil :mode "\\.ts\\'")
(use-package tsx-ts-mode :ensure nil :mode "\\.tsx\\'")
(use-package yaml-ts-mode :ensure nil :mode ("\\.yaml\\'" "\\.yml\\'"))

(use-package org
  :ensure nil
  :custom
  (org-edit-src-content-indentation 4) ;; Set src block automatic indent to 4 instead of 2.
  (org-return-follows-link t)   ;; Sets RETURN key in org-mode to follow links
  (org-file-apps '((auto-mode  . emacs)   ;; Open text/code files inside Emacs
                   (directory  . emacs)   ;; Open directories in dired
                   ("\\.pdf\\'" . default) ;; PDFs in system viewer
                   (t          . emacs)))  ;; Everything else in Emacs too
  ;; Agenda — recursively collect all .org files under ~/org
  (org-agenda-files (directory-files-recursively "~/org" "\\.org$"))
  (org-agenda-span 'week)
  (org-agenda-start-on-weekday 1) ;; Monday
  (org-agenda-window-setup 'current-window) ;; Open agenda in current window, not a split
  (org-agenda-block-separator nil)
  (org-agenda-todo-ignore-scheduled 'future)
  :hook
  (org-mode . org-indent-mode) ;; Indent text
  )

(use-package toc-org
  :commands toc-org-enable
  :hook (org-mode . toc-org-mode))

(use-package org-modern
  :init
  (setq org-modern-star 'replace)
  (setq org-modern-replace-stars '("⟶" "⟶" "⟶" "⟶" "⟶" "⟶" "⟶" "⟶"))
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda)))

(use-package org-agenda
  :ensure nil
  :custom
  ;; Layout
  (org-agenda-prefix-format
   '((agenda . "  %-12:c %?-12t ")
     (todo   . "  %-12:c ")
     (tags   . "  %-12:c ")
     (search . "  %-12:c ")))
  (org-agenda-time-grid
   '((daily today require-timed)
     (800 1000 1200 1400 1600 1800 2000)
     "      " "─────────────────"))
  (org-agenda-current-time-string "◀── now")
  ;; Hide noise
  (org-agenda-show-all-dates nil)         ;; Skip days with nothing
  (org-agenda-skip-deadline-if-done t)
  (org-agenda-skip-scheduled-if-done t)
  (org-agenda-compact-blocks t)
  ;; Tags right-aligned with a gap
  (org-agenda-tags-column -80)
  :config
  (custom-set-faces
   ;; Date headers
   '(org-agenda-date          ((t (:height 1.1 :weight bold :underline nil))))
   '(org-agenda-date-today    ((t (:height 1.15 :weight bold :underline nil :inverse-video nil
                                   :foreground "#fabd2f")))) ;; gruvbox yellow
   '(org-agenda-date-weekend  ((t (:weight normal :foreground "#928374"))))  ;; gruvbox grey
   ;; Time grid lines — subtle
   '(org-time-grid            ((t (:foreground "#504945"))))
   ;; Structure
   '(org-agenda-structure     ((t (:height 1.05 :weight bold :underline nil))))
   ;; Done items fade out
   '(org-agenda-done          ((t (:foreground "#928374" :strike-through t))))
   ;; Deadline / scheduled
   '(org-upcoming-deadline    ((t (:foreground "#fb4934"))))   ;; gruvbox red
   '(org-scheduled-today      ((t (:foreground "#b8bb26"))))   ;; gruvbox green
   '(org-scheduled-previously ((t (:foreground "#fe8019"))))))  ;; gruvbox orange

(defvar start/notes-frame nil
  "Separate frame used for speaker notes during a presentation.")

(defun start/get-slide-notes ()
  "Extract content from the :NOTES: drawer of the current org heading."
  (save-excursion
    (org-back-to-heading t)
    (let ((end (save-excursion (org-end-of-subtree t) (point))))
      (when (re-search-forward "^[ \t]*:NOTES:" end t)
        (let ((start (line-beginning-position 2))
              (stop  (progn (re-search-forward "^[ \t]*:END:" end t)
                            (line-beginning-position))))
          (buffer-substring-no-properties start stop))))))

(defun start/update-notes-frame ()
  "Refresh the speaker notes frame for the current slide."
  (when (and (frame-live-p start/notes-frame)
             (bound-and-true-p org-tree-slide-mode))
    (let ((title (org-get-heading t t t t))
          (notes (start/get-slide-notes)))
      (with-current-buffer (get-buffer-create "*Speaker Notes*")
        (let ((inhibit-read-only t))
          (erase-buffer)
          (unless (eq major-mode 'org-mode) (org-mode))
          (insert "#+TITLE: " title "\n\n")
          (insert (if (string-empty-p notes) "/No notes for this slide./" notes))
          (goto-char (point-min)))))))

(defvar start/notes-overlays nil
  "Overlays that hide :NOTES: drawers during presentation.")

(defun start/hide-notes-drawers ()
  "Cover every :NOTES: drawer with an invisible overlay."
  (setq start/notes-overlays nil)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^[ \t]*:NOTES:" nil t)
      (let* ((beg (line-beginning-position))
             (end (when (re-search-forward "^[ \t]*:END:" nil t)
                    (line-end-position)))
             (ov  (when end (make-overlay beg (1+ end)))))
        (when ov
          (overlay-put ov 'invisible t)
          (push ov start/notes-overlays))))))

(defun start/remove-notes-overlays ()
  "Remove all :NOTES: invisibility overlays."
  (mapc #'delete-overlay start/notes-overlays)
  (setq start/notes-overlays nil))

(defun start/open-notes-frame ()
  "Open a dedicated frame for speaker notes on the secondary monitor."
  (unless (frame-live-p start/notes-frame)
    (let* ((monitors  (display-monitor-attributes-list))
           (secondary (when (> (length monitors) 1) (nth 1 monitors)))
           (geo       (when secondary (alist-get 'geometry secondary)))
           (position  (when geo `((left . ,(nth 0 geo)) (top . ,(nth 1 geo))))))
      (setq start/notes-frame
            (make-frame `((name . "Speaker Notes")
                          (width . 80) (height . 30)
                          (minibuffer . t)
                          ,@position)))))
  (with-selected-frame start/notes-frame
    (switch-to-buffer (get-buffer-create "*Speaker Notes*"))
    (text-scale-set 2))
  (start/update-notes-frame)
  (add-hook 'org-tree-slide-before-narrow-hook #'start/update-notes-frame nil t))

(defun start/close-notes-frame ()
  "Close the speaker notes frame."
  (remove-hook 'org-tree-slide-before-narrow-hook #'start/update-notes-frame t)
  (when (frame-live-p start/notes-frame)
    (delete-frame start/notes-frame)
    (setq start/notes-frame nil)))

(defun start/presentation-setup ()
  (text-scale-increase 4)
  (olivetti-mode 1)
  (display-line-numbers-mode 0)
  (setq-local global-hl-line-mode nil)
  (hl-line-mode 0)
  (whitespace-mode 0)
  (diff-hl-mode 0)
  (setq-local mode-line-format nil)
  (start/hide-notes-drawers)
  (start/open-notes-frame))

(defun start/presentation-end ()
  (text-scale-increase 0)
  (olivetti-mode 0)
  (display-line-numbers-mode 1)
  (hl-line-mode 1)
  (diff-hl-mode 1)
  (kill-local-variable 'mode-line-format)
  (start/remove-notes-overlays)
  (start/close-notes-frame))

(use-package org-tree-slide
  :commands org-tree-slide-mode
  :hook ((org-tree-slide-play . start/presentation-setup)
         (org-tree-slide-stop . start/presentation-end))
  :config
  (org-tree-slide-simple-profile)
  (defvar start/presentation-nav-map (make-sparse-keymap))
  (define-key start/presentation-nav-map (kbd "<right>") #'org-tree-slide-move-next-tree)
  (define-key start/presentation-nav-map (kbd "<left>")  #'org-tree-slide-move-previous-tree)
  (add-to-list 'emulation-mode-map-alists
               `((org-tree-slide-mode . ,start/presentation-nav-map)))
  :custom
  (org-tree-slide-skip-outline-level 2)
  (org-tree-slide-header nil))

(use-package markdown-mode
  :mode (("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode)
         ("README\\.md\\'" . gfm-mode))
  :custom
  (markdown-command "pandoc")
  (markdown-fontify-code-blocks-natively t)
  :config
  (defun start/markdown-preview-eww ()
    "Render current markdown buffer via pandoc and open in eww."
    (interactive)
    (let* ((tmp (make-temp-file "md-preview" nil ".html")))
      (call-process-region (point-min) (point-max)
                           "pandoc" nil `(:file ,tmp) nil
                           "--from=markdown" "--to=html5"
                           "--standalone"
                           "--metadata" "title=Preview")
      (eww-open-file tmp)
      (message "Markdown preview rendered.")))
  (start/leader-keys
    :keymaps 'markdown-mode-map
    "m p" '(start/markdown-preview-eww :wk "Markdown preview (eww)")))

(use-package eat
  :defer
  :hook ('eshell-load-hook #'eat-eshell-mode))

(use-package vterm
  :commands (vterm vterm-other-window)
  :custom
  (vterm-max-scrollback 10000))

(use-package multi-vterm
  :after vterm
  :commands (multi-vterm multi-vterm-next multi-vterm-prev))

(use-package exec-path-from-shell
  :hook (elpaca-after-init . exec-path-from-shell-initialize))

;; (add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; (require 'start-multiFileExample)

;; (start/hello)

(use-package transient
  :defer
  :config
  (define-key transient-map (kbd "<escape>") 'transient-quit-one)) ;; Make escape quit magit prompts

(use-package magit
  :defer
  :custom (magit-diff-refine-hunk (quote all)) ;; Shows inline diff
  :config
  (setopt magit-format-file-function #'magit-format-file-nerd-icons) ;; Magit nerd icons
  )

(use-package magit-delta
  :after magit
  :custom
  (magit-delta-default-dark-theme "gruvbox-dark")
  (magit-delta-hide-plus-minus-markers nil)
  :config
  (magit-delta-mode))

(defun start/ai-review--show (diff context)
  "Send DIFF to gptel with CONTEXT label and display the review."
  (if (string-empty-p (string-trim diff))
      (message "No changes to review.")
    (let ((prompt (format "You are a thorough code reviewer. Review the following git diff concisely — highlight bugs, logic issues, security concerns, and meaningful improvements. Skip style nitpicks. Context: %s\n\n```diff\n%s\n```" context diff)))
      (message "Sending to AI for review...")
      (gptel-request prompt
        :callback (lambda (response _info)
                    (with-current-buffer (get-buffer-create "*AI Review*")
                      (let ((inhibit-read-only t))
                        (erase-buffer)
                        (insert (format "# AI Review — %s\n\n" context))
                        (insert response)
                        (goto-char (point-min))
                        (when (fboundp 'markdown-mode) (markdown-mode)))
                      (display-buffer (current-buffer)
                                      '(display-buffer-in-side-window
                                        (side . right)
                                        (window-width . 0.4)))))))))

(defun start/ai-review-staged ()
  "AI review of staged (index) changes."
  (interactive)
  (start/ai-review--show
   (shell-command-to-string "git diff --cached")
   "staged changes"))

(defun start/ai-review-unstaged ()
  "AI review of all unstaged working tree changes."
  (interactive)
  (start/ai-review--show
   (shell-command-to-string "git diff")
   "unstaged changes"))

(defun start/ai-review-branch ()
  "AI review of all commits on the current branch vs main/master."
  (interactive)
  (let* ((base (or (car (seq-filter
                         (lambda (b) (member b '("main" "master")))
                         (split-string
                          (shell-command-to-string "git branch --format='%(refname:short)'") "\n" t)))
                   "HEAD~1"))
         (diff (shell-command-to-string (format "git diff %s...HEAD" base))))
    (start/ai-review--show diff (format "branch vs %s" base))))

(use-package diff-hl
  :hook ((dired-mode         . diff-hl-dired-mode-unless-remote)
         (magit-post-refresh . diff-hl-magit-post-refresh)
         (elpaca-after-init . global-diff-hl-mode)))

(use-package corfu
  ;; Optional customizations
  :custom
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  (corfu-auto t)                 ;; Enable auto completion
  (corfu-auto-prefix 2)          ;; Minimum length of prefix for auto completion.
  (corfu-popupinfo-mode t)       ;; Enable popup information
  (corfu-popupinfo-delay 0.5)    ;; Lower popup info delay to 0.5 seconds from 2 seconds
  (corfu-separator ?\s)          ;; Orderless field separator, Use M-SPC to enter separator
  ;; (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  ;; (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
  ;; (corfu-preview-current nil)    ;; Disable current candidate preview
  ;; (corfu-preselect 'prompt)      ;; Preselect the prompt
  ;; (corfu-on-exact-match nil)     ;; Configure handling of exact matches
  ;; (corfu-scroll-margin 5)        ;; Use scroll margin
  (completion-ignore-case t)

  ;; Emacs 30 and newer: Disable Ispell completion function.
  ;; Try `cape-dict' as an alternative.
  (text-mode-ispell-word-completion nil)

  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  (tab-always-indent 'complete)

  (corfu-preview-current nil) ;; Don't insert completion without confirmation
  ;; Recommended: Enable Corfu globally.  This is recommended since Dabbrev can
  ;; be used globally (M-/).  See also the customization variable
  ;; `global-corfu-modes' to exclude certain modes.
  :init
  (global-corfu-mode))

(use-package nerd-icons-corfu
  :after corfu
  :init (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package yasnippet-capf :defer)

(defun start/setup-capfs ()
  "Configure completion backends"
  ;; Take care when adding Capfs to the list since each of the Capfs adds a small runtime cost.
  (let ((merge-backends (append
                         (list
                          #'cape-keyword      ;; Keyword completion
                          ;; #'cape-abbrev       ;; Complete abbreviation
                          #'cape-dabbrev      ;; Complete word from current buffers
                          ;; #'cape-line         ;; Complete entire line from current buffer
                          ;; #'cape-history      ;; Complete from Eshell, Comint or minibuffer history
                          ;; #'cape-dict         ;; Dictionary completion (Needs Dictionary file installed)
                          ;; #'cape-tex          ;; Complete Unicode char from TeX command, e.g. \hbar
                          ;; #'cape-sgml         ;; Complete Unicode char from SGML entity, e.g., &alpha
                          ;; #'cape-rfc1345      ;; Complete Unicode char using RFC 1345 mnemonics
                          )
                         (when (fboundp 'snippy-capf)
                           (list #'snippy-capf)) ;; Vscode snippets (optional Snippy)
                         (list #'yasnippet-capf) ;; Yasnippet snippets
                         ))
        (seperate-backends (list
                            #'cape-file ;; Path completion
                            #'cape-elisp-block ;; Complete elisp in Org or Markdown mode
                            )))
    ;; Remove keyword completion in git commits
    (when (derived-mode-p 'git-commit-mode)
      (setq merge-backends (remq #'cape-keyword merge-backends)))

    ;; Add Elisp symbols only in Elisp modes
    (when (derived-mode-p 'emacs-lisp-mode 'ielm-mode)
      (setq merge-backends (cons #'cape-elisp-symbol merge-backends))) ;; Emacs Lisp code (functions, variables)

    ;; Add Eglot to the front of the list if it's active
    (when (bound-and-true-p eglot--managed-mode)
      (setq merge-backends (cons #'eglot-completion-at-point merge-backends)))

    ;; Create the super-capf and set it buffer-locally
    (setq-local completion-at-point-functions
                (append
                 seperate-backends
                 (list (apply #'cape-capf-super merge-backends)))
                )))

(use-package cape
  :after (corfu)
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.  The order of the functions matters, the
  ;; first function returning a result wins.  Note that the list of buffer-local
  ;; completion functions takes precedence over the global list.

  ;; Seperate function needed, because we use setq-local (everything is replaced)
  (add-hook 'eglot-managed-mode-hook #'start/setup-capfs)
  (add-hook 'prog-mode-hook #'start/setup-capfs)
  (add-hook 'text-mode-hook #'start/setup-capfs))

(use-package orderless
  :defer
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package vertico
  :hook (elpaca-after-init . vertico-mode)
  ;; Vim keybinds
  :bind (:map vertico-map
             ("C-j" . vertico-next)
             ("C-k" . vertico-previous)
             ("C-u" . vertico-scroll-down)
             ("C-d" . vertico-scroll-up))
  :custom
  (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  )

(savehist-mode) ;; Enables save history mode

(use-package marginalia
  :after vertico
  :config
  (marginalia-mode))

(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  :hook
  (marginalia-mode . nerd-icons-completion-marginalia-setup))

(use-package embark :defer)
(use-package embark-consult
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(defun start/setup-ispell-fallback ()
  "Configure flyspell with hunspell/aspell when jinx is unavailable."
  (let ((spell-program (or (executable-find "hunspell")
                           (executable-find "aspell"))))
    (if spell-program
        (progn
          (setq ispell-program-name spell-program
                ispell-dictionary "en_US")
          (add-hook 'text-mode-hook #'flyspell-mode)
          (add-hook 'prog-mode-hook #'flyspell-prog-mode)
          (message "Spelling backend: %s + flyspell"
                   (file-name-nondirectory spell-program)))
      (message "No spelling backend found. Install enchant (for jinx) or hunspell/aspell."))))

(defun start/enable-spelling ()
  "Enable jinx globally, fallback to flyspell if jinx fails."
  (condition-case err
      (if (require 'jinx nil t)
          (progn
            (setq jinx-languages "en_US nb_NO")
            (global-jinx-mode 1)
            (message "Spelling backend: jinx"))
        (start/setup-ispell-fallback))
    (error
     (message "Jinx unavailable (%s), using flyspell fallback."
              (error-message-string err))
     (start/setup-ispell-fallback))))

(defun start/toggle-spelling ()
  "Toggle spelling in the current buffer."
  (interactive)
  (cond
   ((bound-and-true-p jinx-mode)
    (jinx-mode -1)
    (message "Jinx disabled in buffer"))
   ((fboundp 'jinx-mode)
    (jinx-mode 1)
    (message "Jinx enabled in buffer"))
   ((bound-and-true-p flyspell-mode)
    (flyspell-mode -1)
    (message "Flyspell disabled in buffer"))
   (t
    (flyspell-mode 1)
    (message "Flyspell enabled in buffer"))))

(defun start/correct-word-at-point ()
  "Correct spelling at point using jinx or ispell."
  (interactive)
  (cond
   ((fboundp 'jinx-correct) (call-interactively #'jinx-correct))
   ((fboundp 'ispell-word) (call-interactively #'ispell-word))
   (t (user-error "No spelling command available"))))

(use-package jinx
  :defer t
  :commands (jinx-mode jinx-correct global-jinx-mode))

(use-package emacs
  :ensure nil
  :hook (elpaca-after-init . start/enable-spelling))

(use-package gptel
  :commands (gptel))

(use-package track-changes
  :defer)

(use-package copilot
  :ensure (:host github :repo "copilot-emacs/copilot.el")
  :after track-changes
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . copilot-accept-completion)
              ("TAB" . copilot-accept-completion)
              ("C-<tab>" . copilot-accept-completion-by-word)
              ("C-TAB" . copilot-accept-completion-by-word)))

(use-package agent-shell
    :ensure t
    :ensure-system-package
    ;; Add agent installation configs here
    ((claude . "brew install claude-code")
     (claude-agent-acp . "npm install -g @zed-industries/claude-agent-acp")))

(use-package consult
  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :init
  ;; Optionally configure the register formatting. This improves the register
  ;; preview for `consult-register', `consult-register-load',
  ;; `consult-register-store' and the Emacs built-ins.
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :config
  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))

  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  ;; (consult-customize
  ;; consult-theme :preview-key '(:debounce 0.2 any)
  ;; consult-ripgrep consult-git-grep consult-grep
  ;; consult-bookmark consult-recent-file consult-xref
  ;; consult--source-bookmark consult--source-file-register
  ;; consult--source-recent-file consult--source-project-recent-file
  ;; :preview-key "M-."
  ;; :preview-key '(:debounce 0.4 any))

  ;; By default `consult-project-function' uses `project-root' from project.el.
  ;; Optionally configure a different project root function.
   ;;;; 1. project.el (the default)
  ;; (setq consult-project-function #'consult--default-project--function)
   ;;;; 2. vc.el (vc-root-dir)
  ;; (setq consult-project-function (lambda (_) (vc-root-dir)))
   ;;;; 3. locate-dominating-file
  ;; (setq consult-project-function (lambda (_) (locate-dominating-file "." ".git")))
   ;;;; 4. projectile.el (projectile-project-root)
  (autoload 'projectile-project-root "projectile")
  (setq consult-project-function (lambda (_) (projectile-project-root)))
   ;;;; 5. No project support
  ;; (setq consult-project-function nil)
  )

;; Persistent toggle state for in-file search
(defvar start/search-case-sensitive nil
  "When non-nil, search is case sensitive (overrides case-fold-search).")
(defvar start/search-use-regexp nil
  "When non-nil, use regular expression search/replace.")
(defvar start/search-whole-word nil
  "When non-nil, match whole words only (wraps pattern in \\b…\\b).")

;; --- Toggle suffixes (stay in the transient) ---
(transient-define-suffix start/search--toggle-case ()
  :description (lambda ()
                 (concat "Case sensitive  "
                         (if start/search-case-sensitive
                             (propertize "[ON]" 'face 'transient-value)
                           (propertize "[off]" 'face 'transient-inactive-value))))
  :transient t
  (interactive)
  (setq start/search-case-sensitive (not start/search-case-sensitive)))

(transient-define-suffix start/search--toggle-regexp ()
  :description (lambda ()
                 (concat "Regexp mode     "
                         (if start/search-use-regexp
                             (propertize "[ON]" 'face 'transient-value)
                           (propertize "[off]" 'face 'transient-inactive-value))))
  :transient t
  (interactive)
  (setq start/search-use-regexp (not start/search-use-regexp)))

(transient-define-suffix start/search--toggle-word ()
  :description (lambda ()
                 (concat "Whole word      "
                         (if start/search-whole-word
                             (propertize "[ON]" 'face 'transient-value)
                           (propertize "[off]" 'face 'transient-inactive-value))))
  :transient t
  (interactive)
  (setq start/search-whole-word (not start/search-whole-word)))

;; --- Action suffixes (exit transient) ---
(transient-define-suffix start/search--do-search ()
  :description "Search  (live minibuffer)"
  (interactive)
  (let ((case-fold-search (not start/search-case-sensitive)))
    (consult-line)))

(transient-define-suffix start/search--do-occur ()
  :description "Occur   (results buffer)"
  (interactive)
  (let* ((case-fold-search (not start/search-case-sensitive))
         (initial (when (use-region-p)
                    (buffer-substring-no-properties (region-beginning) (region-end))))
         (raw (read-string "Occur: " initial))
         (pattern (cond
                   (start/search-use-regexp raw)
                   (start/search-whole-word (format "\\b%s\\b" (regexp-quote raw)))
                   (t (regexp-quote raw)))))
    (occur pattern)))

(transient-define-suffix start/search--do-replace ()
  :description "Replace (query-replace)"
  (interactive)
  (let ((case-fold-search (not start/search-case-sensitive)))
    (if start/search-use-regexp
        (call-interactively #'query-replace-regexp)
      (call-interactively #'query-replace))))

;; --- The transient prefix ---
(transient-define-prefix start/search-in-file ()
  "In-file search and replace with toggleable options."
  [:description "Toggle options"
   ("c" start/search--toggle-case)
   ("r" start/search--toggle-regexp)
   ("w" start/search--toggle-word)]
  [["Actions"
    ("s" start/search--do-search)
    ("o" start/search--do-occur)
    ("%" start/search--do-replace)
    ("q" "Quit" transient-quit-one)]])

;; Nice occur-mode navigation with evil: n/p move between matches
(with-eval-after-load 'evil
  (evil-define-key 'normal occur-mode-map
    (kbd "n") #'occur-next
    (kbd "p") #'occur-prev
    (kbd "RET") #'occur-mode-goto-occurrence))

(use-package helpful
  :bind
  ;; Note that the built-in `describe-function' includes both functions
  ;; and macros. `helpful-function' is functions only, so we provide
  ;; `helpful-callable' as a drop-in replacement.
  ("C-h f" . helpful-callable)
  ("C-h v" . helpful-variable)
  ("C-h k" . helpful-key)
  ("C-h x" . helpful-command)
  )

(use-package diminish :defer)

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package hl-todo
  :hook
  ((prog-mode yaml-ts-mode) . hl-todo-mode)
  :config
  ;; From doom emacs
  (setq hl-todo-highlight-punctuation ":"
        hl-todo-keyword-faces
        '(;; For reminders to change or add something at a later date.
          ("TODO" warning bold)
          ;; For code (or code paths) that are broken, unimplemented, or slow,
          ;; and may become bigger problems later.
          ("FIXME" error bold)
          ;; For code that needs to be revisited later, either to upstream it,
          ;; improve it, or address non-critical issues.
          ("REVIEW" font-lock-keyword-face bold)
          ;; For code smells where questionable practices are used
          ;; intentionally, and/or is likely to break in a future update.
          ("HACK" font-lock-constant-face bold)
          ;; For sections of code that just gotta go, and will be gone soon.
          ;; Specifically, this means the code is deprecated, not necessarily
          ;; the feature it enables.
          ("DEPRECATED" font-lock-doc-face bold)
          ;; Extra keywords commonly found in the wild, whose meaning may vary
          ;; from project to project.
          ("NOTE" success bold)
          ("BUG" error bold)
          ("XXX" font-lock-constant-face bold)))
  )

(use-package indent-guide
  :hook
  (prog-mode . indent-guide-mode)
  :config
  (setq indent-guide-char "│")) ;; Set the character used for the indent guide.

(use-package which-key
  :ensure nil ;; Don't install which-key because it's now built-in
  :hook (elpaca-after-init . which-key-mode)
  :diminish
  :custom
  (which-key-side-window-location 'bottom)
  (which-key-sort-order #'which-key-key-order-alpha) ;; Same as default, except single characters are sorted alphabetically
  (which-key-sort-uppercase-first nil)
  (which-key-add-column-padding 1) ;; Number of spaces to add to the left of each column
  (which-key-min-display-lines 6)  ;; Increase the minimum lines to display because the default is only 1
  (which-key-idle-delay 0.8)       ;; Set the time delay (in seconds) for the which-key popup to appear
  (which-key-max-description-length 25)
  (which-key-allow-imprecise-window-fit nil)) ;; Fixes which-key window slipping out in Emacs Daemon

(use-package ws-butler
  :hook (elpaca-after-init . ws-butler-global-mode))

(use-package ag
  :commands (ag ag-project))
