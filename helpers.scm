(provide remove-char)
(provide insert-char)
(provide sublist)
(provide filter)
(provide map-index)

(define (remove-char str index-to-remove-at)
  (define str-len (string-length str))
  (if (or (< index-to-remove-at 0) (>= index-to-remove-at str-len))
      str
      (string-append (substring str 0 index-to-remove-at)
                     (substring str (+ index-to-remove-at 1) str-len))))

(define (insert-char str char index-to-insert-at)
  (string-append (substring str 0 index-to-insert-at)
                 (list->string (list char))
                 (substring str index-to-insert-at (string-length str))))

(define (sublist lst start length) (take (drop lst start) length))

(define (filter lst check) (filter-loop '() lst check))
(define (filter-loop out listLeft check)
  (if (empty? listLeft)
      out
      (begin
        (define firstElem (first listLeft))
        (filter-loop (if (check firstElem) (append out (list firstElem)) out)
                     (cdr listLeft)
                     check))))

(define (map-index lst func)
  (define index (box 0))
  (map (lambda (elem)
               (define indexVal (unbox index))
               (set-box! index (+ indexVal 1))
               (func indexVal elem)) lst))
