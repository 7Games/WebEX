;;; webex.lisp --- Website Exporter

;;; Commentary:

;; A templating system built around website creation

;;; Code:

;;;;;;;;;;;;;
;; Project ;;
;;;;;;;;;;;;;

(defclass site ()
  ((name
    :initarg :name
    :accessor site-name
    :type string
    :initform "Untitled"
    :documentation "Name for the site.")
   (static
    :initarg :static
    :accessor site-static
    :type list
    :initform '()
    :documentation "List of static files to be copied over.")
   (pages
    :initarg :pages
    :accessor site-pages
    :type list
    :initform '()
    :documentation "List of `page' that will be exported.")
   (additional-data
    :initarg :additional-data
    :accessor site-additional-data
    :type list
    :initform '())))

(defun create-site (site-var site-name)
  "Creates site inside of `site-var' with name `site-name'."
  (setf (symbol-value site-var) (make-instance 'site :name site-name))
  site-var)

(defun register-page (site page)
  "Add `page' to the pages list in `site'."
  (setf (site-pages site) (cons page (site-pages site))))

(defun add-static (site input-file export-path)
  (push (cons input-file export-path) (site-static site)))

(defun export-static (site export-path)
  (loop for file in (site-static site)
        do (when file (copy-file (car file) (string-concat export-path (cdr file))))))

(defun site-find-additonal-data (site data-name)
  (loop for data in (site-additional-data site)
        do (if (equal (nth 0 data) data-name)
               (return-from site-find-additonal-data data)))
  nil)

(defun site-add-additonal-data (site data-name data-content)
  (setf (site-additional-data site) (cons (cons data-name data-content) (site-additional-data site))))

;;;;;;;;;;
;; Page ;;
;;;;;;;;;;

(defclass page ()
  ((name
    :initarg :name
    :accessor page-name
    :type list
    :initform '())
   (export-file
    :initarg :export-file
    :accessor page-export-file
    :type string
    :initform "")
   (elements
    :initarg :elements
    :accessor page-elements
    :type list
    :initform '())
   (additional-data
    :initarg :additional-data
    :accessor page-additional-data
    :type list
    :initform '())))

(defmacro create-page (site page-name page-export-file &body body)
  `(let ((page-var (make-instance 'page :name ,page-name
                                  :export-file ,page-export-file)))
     ,@body ;; Run whatever is in body
     (setf (page-elements page-var) (reverse (page-elements page-var))) ;; Rev
     (register-page ,site page-var))) ;; Register it on the wanted site

(defun add-element (page element)
  (setf (page-elements page) (cons element (page-elements page))))

(defun find-additonal-data (page data-name)
  (loop for data in (page-additional-data page)
        do (if (equal (nth 0 data) data-name)
               (return-from find-additonal-data data)))
  nil)

(defmacro add-additonal-data (data-name data-content)
  `(progn (setf (page-additional-data page-var)
                (cons (cons ,data-name ,data-content) (page-additional-data page-var)))))

;;;;;;;;;;;;;;
;; Elements ;;
;;;;;;;;;;;;;;

(deftype element-type () '(member :heading
                                  :subheading
                                  :text
                                  :link
                                  :paragraph
                                  :codeblock
                                  :inline-codeblock
                                  :mixer
                                  :image
                                  :newline
                                  :separator))

(deftype list-type () '(member :unordered
                               :ordered))

(defclass element ()
  ((type
    :initarg :type
    :accessor element-type
    :type element-type
    :initform :text)))

(defclass element-heading (element)
  ((content
    :initarg :content
    :accessor element-heading-content
    :type string
    :initform "")))

(defclass element-subheading (element)
  ((content
    :initarg :content
    :accessor element-subheading-content
    :type string
    :initform "")))

(defclass element-text (element)
  ((content
    :initarg :content
    :accessor element-text-content
    :type string
    :initform "")))

(defclass element-link (element)
  ((text
    :initarg :text
    :accessor element-link-text
    :type string
    :initform "")
   (url
    :initarg :url
    :accessor element-link-url
    :type string
    :initform "")))

(defclass element-paragraph (element)
  ((elements
    :initarg :elements
    :accessor element-paragraph-elements
    :type list
    :initform '())))

(defclass element-mixer (element)
  ((elements
    :initarg :elements
    :accessor element-mixer-elements
    :type list
    :initform '())))

(defclass element-codeblock (element)
  ((content
    :initarg :content
    :accessor element-codeblock-content
    :type string
    :initform "")))

(defclass element-inline-codeblock (element)
  ((content
    :initarg :content
    :accessor element-inline-codeblock-content
    :type string
    :initform "")))

(defclass element-list (element)
  ((list-type
    :initarg :list-type
    :accessor element-list-type
    :type list-type
    :initform :unordered)
   (elements
    :initarg :elements
    :accessor element-list-elements
    :type list
    :initform '())))

(defclass element-image (element)
  ((file
    :initarg :file
    :accessor element-image-file
    :type string
    :initform "")
   (alt
    :initarg :alt
    :accessor element-image-alt
    :type string
    :initform "")))

(defclass element-newline (element) ())

(defclass element-separator (element) ())

;; User-facing helpers for creating elements

(defun create-heading (text)
  (make-instance 'element-heading :type :heading :content text))

(defun create-subheading (text)
  (make-instance 'element-subheading :type :subheading :content text))

(defun create-text (text)
  (make-instance 'element-text :type :text :content text))

(defun create-codeblock (text)
  (make-instance 'element-codeblock :type :codeblock :content text))

(defun create-inline-codeblock (text)
  (make-instance 'element-inline-codeblock :type :inline-codeblock :content text))

(defun create-link (text url)
  (make-instance 'element-link :type :link :text text :url url))

(defun create-paragraph (elements)
  (make-instance 'element-paragraph :type :paragraph :elements elements))

(defun create-mixer (elements)
  (make-instance 'element-mixer :type :mixer :elements elements))

(defun create-list (list-type elements)
  (make-instance 'element-list :type :list :list-type list-type :elements (list elements)))

(defun create-image (file-path alt-text)
  (make-instance 'element-image :type :image :file file-path :alt alt-text))

(defun create-new-line ()
  (make-instance 'element-newline :type :newline))

(defun create-separator ()
  (make-instance 'element-separator :type :separator))

;; User-facing helpers for creating and adding elements

(defmacro add-heading (text)
  `(progn (add-element page-var (create-heading ,text))))

(defmacro add-subheading (text)
  `(progn (add-element page-var (create-subheading ,text))))

(defmacro add-text (text)
  `(progn (add-element page-var (create-text ,text))))

(defmacro add-codeblock (text)
  `(progn (add-element page-var (create-codeblock ,text))))

(defmacro add-inline-codeblock (text)
  `(progn (add-element page-var (create-inline-codeblock ,text))))

(defmacro add-link (text url)
  `(progn (add-element page-var (create-link ,text ,url))))

(defmacro add-paragraph (&rest elements)
  `(progn (add-element page-var (create-paragraph (list ,@elements)))))

(defmacro add-mixer (&rest elements)
  `(progn (add-element page-var (create-mixer (list ,@elements)))))

(defmacro add-list (list-type &rest elements)
  `(progn (add-element page-var (create-list ,list-type (list ,@elements)))))

(defmacro add-image (file-path &optional alt-text)
  `(progn (add-element page-var (create-image ,file-path ,alt-text))))

(defmacro add-new-line ()
  `(progn (add-element page-var (create-new-line))))

(defmacro add-separator ()
  `(progn (add-element page-var (create-separator))))

;;;;;;;;;;;;;
;; Helpers ;;
;;;;;;;;;;;;;

(defmacro add-indentation (&optional (offset 0))
  `(progn (make-string (+ indentation ,offset) :initial-element #\Space)))

;; Modified from https://lispcookbook.github.io/cl-cookbook/dates_and_times.html
(defun get-timestamp ()
  (multiple-value-bind
        (second minute hour day month year day-of-week dst-p tz)
      (get-decoded-time)
    (format nil "~d-~2,'0d-~2,'0d ~2,'0d:~2,'0d:~2,'0d" ;; on a sidenote, that is a horrible formatting syntax gods DAYUM
            year
            month
            day
            hour
            minute
            second)))

;; Both modified from https://lispcookbook.github.io/cl-cookbook/strings.html
(defun string-split-by-delim (string delim)
  (loop for i = 0 then (1+ j)
        as j = (position delim string :start i)
        collect (subseq string i j)
        while j))
(defun join-string-list (string-list &optional delim)
  (let ((delim-char (if delim delim " ")))
    (format nil (string-concat "~{~A~^" delim-char "~}") string-list)))

(defun get-file-name (file-path)
  "Returns the file name of a given path"
  (nth 0 (reverse (string-split-by-delim file-path #\/))))

(defun get-file-root (file-path)
  "Returns the file's base directory from a given path"
  (string-concat (join-string-list (reverse (cdr (reverse (string-split-by-delim file-path #\/)))) "/") "/"))

;;; webex.lisp ends here
