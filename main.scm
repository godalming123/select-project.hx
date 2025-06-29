(require-builtin helix/components)
(require "helix/commands.scm")
(require "helix/misc.scm")
(require "helpers.scm")

(provide select-project)
(provide add-project)
(provide edit-projects)

(struct ProjectSelector (search-query
                         cursor-position-in-search-query
                         projects
                         fuzzy-matched-projects
                         selected-index))

(define (get-selected-index state) (unbox (ProjectSelector-selected-index state)))

(define (get-project-selector-geometry rect)
  (define available-height (- (area-height rect) 2))
  (define horizontal-padding (round (/ (area-width rect) 15)))
  (define vertical-padding (round (/ available-height 15)))
  (area horizontal-padding
        vertical-padding
        (- (area-width rect) (* 2 horizontal-padding))
        (- available-height (* 2 vertical-padding))))

(define (render-project-selector state rect frame)
  (define normal-style (theme-scope *helix.cx* "ui.text"))
  (define selected-style (theme-scope *helix.cx* "ui.text.focus"))
  (define outer-area (get-project-selector-geometry rect))
  (define inner-area-x (+ (area-x outer-area) 1))
  (define inner-area-y (+ (area-y outer-area) 1))
  (define inner-height (- (area-height outer-area) 4))
  (define inner-width (- (area-width outer-area) 2))
  (define selected-index (get-selected-index state))
  (define first-rendered-project-index (- selected-index (modulo selected-index inner-height)))
  (buffer/clear frame outer-area)
  (block/render frame outer-area (make-block (theme->bg *helix.cx*) (theme->bg *helix.cx*) "all" "plain"))

  (block/render frame (area inner-area-x inner-area-y inner-width 2) (make-block (theme->bg *helix.cx*) (theme->bg *helix.cx*) "bottom" "plain"))
  (frame-set-string! frame (+ inner-area-x 1) inner-area-y (unbox (ProjectSelector-search-query state)) normal-style)

  (map-index
    (sublist (unbox (ProjectSelector-fuzzy-matched-projects state)) first-rendered-project-index inner-height)
    (lambda (index elem)
      (define x (+ (area-x outer-area) 1))
      (define y (+ (area-y outer-area) index 3))
      (define selected (equal? (+ index first-rendered-project-index) selected-index))
      (when (and selected (Color? (style->bg selected-style)))
            (buffer/clear-with frame (area x y inner-width 1) selected-style))
      (frame-set-string! frame (+ x 1) y (string-append (if selected "> " "  ") elem) (if selected selected-style normal-style)))))

(define (get-project-selector-cursor-position state rect)
  (define block-area (get-project-selector-geometry rect))
  (position (+ (area-y block-area) 1)
            (+ (area-x block-area) 2 (unbox (ProjectSelector-cursor-position-in-search-query state)))))

(define (set-selected-index-wrapping state new-selected-index)
  (set-box! (ProjectSelector-selected-index state)
            (modulo new-selected-index (length (unbox (ProjectSelector-fuzzy-matched-projects state))))))

(define (set-cursor-pos state new-cursor-pos)
  (define new-cursor-pos-constrained (max 0 (min new-cursor-pos (string-length (unbox (ProjectSelector-search-query state))))))
  (set-box! (ProjectSelector-cursor-position-in-search-query state) new-cursor-pos-constrained))

(define (set-search-query state new-search-query)
  (set-box! (ProjectSelector-search-query state) new-search-query)
  (set-box! (ProjectSelector-fuzzy-matched-projects state)
            (fuzzy-match new-search-query
                         (ProjectSelector-projects state))))

(define (handle-project-selector-event state event)
  (define char (key-event-char event))
  (define selected-index (get-selected-index state))
  (define cursor-pos (unbox (ProjectSelector-cursor-position-in-search-query state)))
  (define search-query-len (string-length (unbox (ProjectSelector-search-query state))))
  (cond [(key-event-escape? event) event-result/close]
        [(key-event-enter? event)
         (begin (change-current-directory (list-ref (unbox (ProjectSelector-fuzzy-matched-projects state)) selected-index))
                event-result/close)]
        [else (begin
          (cond [(key-event-up? event) (set-selected-index-wrapping state (- selected-index 1))]
                [(key-event-down? event) (set-selected-index-wrapping state (+ selected-index 1))]
                [(key-event-right? event) (set-cursor-pos state (+ cursor-pos 1))]
                [(key-event-left? event) (set-cursor-pos state (- cursor-pos 1))]
                [(key-event-home? event) (set-cursor-pos state 0)]
                ;[(key-event-end? event) (set-cursor-pos state search-query-len)] ; for some reason, `key-event-end?` is not a function
                [(key-event-backspace? event)
                 (begin (set-search-query state (remove-char (unbox (ProjectSelector-search-query state)) (- cursor-pos 1)))
                        (set-cursor-pos state (- cursor-pos 1)))]
                [(char? char)
                 (begin (set-search-query state (insert-char (unbox (ProjectSelector-search-query state)) char cursor-pos))
                        (set-cursor-pos state (+ cursor-pos 1)))])
          event-result/consume)]))

(define PROJECTS-FILE (canonicalize-path "~/.projects"))

(define (get-projects)
  (if (path-exists? PROJECTS-FILE)
      (~> (open-input-file PROJECTS-FILE)
          (read-port-to-string)
          (split-many "\n")
          ((lambda (lst) (map trim lst)))
          (filter (lambda (project) (not (equal? project "")))))
      '()))

;;@doc
;; Opens the `~/.projects` file to edit the list of projects
(define (edit-projects) (open PROJECTS-FILE))

;;@doc
;; Adds the current working directory as a project
(define (add-project)
  ; TODO: When appending to files is supported in steel: Instead of overwriting the whole file, just append to it
  (define projects (append (get-projects) (list (canonicalize-path "."))))
  (display (string-join projects "\n") (open-output-file PROJECTS-FILE))
)

;;@doc
;; Shows all of the projects in a picker where selecting a project sets the working directory to that projects directory.
(define (select-project)
  (define projects (get-projects))
  (push-component! (new-component!
                    "Project selector"
                    (ProjectSelector (box "") (box 0) projects (box projects) (box 0))
                    render-project-selector
                    (hash "handle_event" handle-project-selector-event "cursor" get-project-selector-cursor-position))))
