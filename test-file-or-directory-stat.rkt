#lang errortrace racket/base

(module+ test
  (require
    racket/file
    racket/math
    rackunit
    rackunit/text-ui)

  (run-tests
    (test-suite "Reading stat info"
      (test-case "Writing temporary file and reading stat"
        (define start-time-milliseconds (current-inexact-milliseconds))
        (define temp-file-path (make-temporary-file))
        (define TEST-STRING "stat test")
        (display-to-file TEST-STRING temp-file-path #:exists 'truncate)
        (define stat-result (file-or-directory-stat temp-file-path))
        (define (stat-ref symbol) (hash-ref stat-result symbol))
        ; Check size, inode, hardlink count and device id.
        (check-equal? (stat-ref 'size) (string-length TEST-STRING))
        (check-equal? (stat-ref 'hardlink-count) 1)
        (define (positive-fixnum? n) (and (positive-integer? n) (fixnum? n)))
        (check-pred positive-fixnum? (stat-ref 'inode))
        (check-pred positive-fixnum? (stat-ref 'device-id))
        ; Check timestamps.
        (check-equal? (quotient (stat-ref 'modify-time-nanoseconds) #e1e9)
                      (stat-ref 'modify-time-seconds))
        (check-equal? (quotient (stat-ref 'access-time-nanoseconds) #e1e9)
                      (stat-ref 'access-time-seconds))
        (check-equal? (quotient (stat-ref 'change-time-nanoseconds) #e1e9)
                      (stat-ref 'change-time-seconds))
        (check-equal? (stat-ref 'modify-time-seconds)
                      (file-or-directory-modify-seconds temp-file-path))
        (check-equal? (stat-ref 'change-time-nanoseconds)
                      (stat-ref 'modify-time-nanoseconds))
        (check-true (>= (stat-ref 'access-time-nanoseconds)
                        (stat-ref 'modify-time-nanoseconds)))
        ; Check stat data that corresponds to mode bits.
        ;  Read/write/execute
        (check-equal? (bitwise-and (stat-ref 'permission-bits) #o777) #o664)
        ; (check-equal? (sort (stat-ref 'permissions)) '(read write))
        ; TODO: Make sure the file is removed even if `file-or-directory-stat`
        ; raises an exception.
        (delete-file temp-file-path))
  ))
)