;;; html.lisp --- HTML Export template for WebEX

;;; Commentary:

;; For exporting WebEX format to HTML

;;; Code:

;;;;;;;;;;;;;;;
;; Constants ;;
;;;;;;;;;;;;;;;

(defconstant *html--export-dir* "HTML")

;;;;;;;;;;;;;
;; Helpers ;;
;;;;;;;;;;;;;

(defun html--eval-element-list (elements)
  (let ((str ""))
    (loop for element in elements
          do (setf str (string-concat str (element-to-html 0 element))))
    str))

(defun html--eval-element-list-fixed (prefix postfix elements)
  (let ((str ""))
    (loop for element in elements
          do (setf str (string-concat str prefix (element-to-html 0 element) postfix)))
    str))

(defun html--remove-spaces (str char)
  (join-string-list (string-split-by-delim str #\Space) char))

(defun html--fixup-string (str)
  (string-downcase (html--remove-spaces str "-")))

;;;;;;;;;;;;;;;;;;;;;;;;
;; WebEX to HTML tags ;;
;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric --element-to-html (indentation type element))

(defmethod --element-to-html (indentation (type (eql :heading)) element)
  (let* ((text (element-heading-content element))
         (text-fixup (html--fixup-string text)))
    (string-concat (add-indentation) "<h1 id=\"" text-fixup "\">" text "</h1>")))

(defmethod --element-to-html (indentation (type (eql :subheading)) element)
  (let* ((text (element-subheading-content element))
         (text-fixup (html--fixup-string text)))
    (string-concat (add-indentation) "<h2 id=\"" text-fixup "\">" text "</h2>")))

(defmethod --element-to-html (indentation (type (eql :paragraph)) element)
  (string-concat (add-indentation) "<p>" (html--eval-element-list (element-paragraph-elements element)) "</p>"))

(defmethod --element-to-html (indentation (type (eql :mixer)) element)
  (string-concat (add-indentation) (html--eval-element-list (element-mixer-elements element))))

(defmethod --element-to-html (indentation (type (eql :text)) element)
  (string-concat (add-indentation) (element-text-content element)))

(defmethod --element-to-html (indentation (type (eql :link)) element)
  (string-concat (add-indentation) "<a href=\"" (element-link-url element) "\">" (element-link-text element) "</a>"))

(defmethod --element-to-html (indentation (type (eql :list)) element)
  (let ((list-str (if (eq (element-list-type element) :unordered) "ul" "ol")))
    (string-concat (add-indentation) "<" list-str ">" ;; <LIST>
                   (html--eval-element-list-fixed
                    (string-concat
                     (STRING #\Newline)
                     (add-indentation 4)
                     "<li>")
                    "</li>"
                    (car (element-list-elements element))) ;; <li>ITEM</li>
                   (string #\Newline) (add-indentation) "</" list-str ">"))) ;; </LIST>

(defmethod --element-to-html (indentation (type (eql :image)) element)
  (string-concat (add-indentation) "<img src=\"" (element-image-file element) "\" alt=\"" (element-image-alt element) "\"/>"))

(defmethod --element-to-html (indentation (type (eql :codeblock)) element)
  (string-concat "<div class=\"code\">" (element-codeblock-content element) "</div>"))

(defmethod --element-to-html (indentation (type (eql :inline-codeblock)) element)
  (string-concat "<span class=\"inline-code\">" (element-inline-codeblock-content element) "</span>"))

(defmethod --element-to-html (indentation (type (eql :newline)) element)
  (string-concat (add-indentation) "<br />"))

(defmethod --element-to-html (indentation (type (eql :separator)) element)
  (string-concat (add-indentation) "<hr />"))

(defun element-to-html (indentation element)
  (if element (--element-to-html indentation (element-type element) element)))

;;;;;;;;;;;;
;; Export ;;
;;;;;;;;;;;;

(defun write-page-to-html (site page)
  (ensure-directories-exist (get-file-root (string-concat "./out/" (site-name site) "/" *html--export-dir* (page-export-file page))))
  (with-open-file (stream (string-concat "./out/" (site-name site) "/" *html--export-dir* (page-export-file page) ".html")
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (let ((page-var page)) (add-additonal-data 'export-date (get-timestamp)))
    (format stream "<!DOCTYPE html>~%<html lang=\"en\">~%    <head>~%        <meta charset=\"UTF-8\">~%        <title>~A</title>~%" (page-name page))
    (if (find-additonal-data page 'css-path)
        (format stream "        <link rel=\"stylesheet\" href=\"~A\">~%" (cdr (find-additonal-data page 'css-path))))
    (format stream "    </head>~%    <body>~%")
    ;; Header ;;;;;;;;;;;;;;;;;;;;;;;;;;
    (when (site-find-additonal-data site 'html-header)
      (format stream "        <header>~%")
      (loop for e in (cdr (site-find-additonal-data site 'html-header))
            do (format stream "~A" (element-to-html (+ 4 8) e))
            (format stream "~%"))
      (format stream "        </header>~%"))
    ;; End of Header ;;;;;;;;;;;;;;;;;;;;
    (loop for e in (page-elements page)
          do (format stream "~A" (element-to-html 8 e))
          (format stream "~%"))
    ;; Footer ;;;;;;;;;;;;;;;;;;;;;;;;;;
    (when (site-find-additonal-data site 'html-footer)
      (format stream "        <footer>~%")
      (loop for e in (cdr (site-find-additonal-data site 'html-footer))
            do (format stream "~A" (element-to-html (+ 4 8) e))
            (format stream "~%"))
      (format stream "        </footer>~%"))
    ;; End of Footer ;;;;;;;;;;;;;;;;;;;;
    (format stream "    </body>~%")
    (format stream "</html>")
    (write-line "" stream)))

(defun export-to-html (site)
  (format t "Exporting site to HTML...~%")
  (ensure-directories-exist (string-concat "./out/" (site-name site) "/" *html--export-dir* "/"))
  (export-static site (string-concat "./out/" (site-name site) "/" *html--export-dir*))
  (loop for page in (site-pages site)
        do (if page (write-page-to-html site page)))
  (format t "Site exported to ~A~%" (string-concat "./out/" (site-name site) "/" *html--export-dir* "/")))

;;;;;;;;;;;;;;;;;;;
;; Add to export ;;
;;;;;;;;;;;;;;;;;;;

(defmacro html-add-styling (css-path)
  `(progn (add-additonal-data 'css-path ,css-path)))

(defmacro html-add-footer (site &body body)
  `(let ((page-var (make-instance 'page :name "don't matter"
                                  :export-file "nowhere")))
     ,@body
     (setf (page-elements page-var) (reverse (page-elements page-var)))
     (site-add-additonal-data ,site 'html-footer (page-elements page-var))))

(defmacro html-add-header (site &body body)
  `(let ((page-var (make-instance 'page :name "don't matter"
                                  :export-file "nowhere")))
     ,@body
     (setf (page-elements page-var) (reverse (page-elements page-var)))
     (site-add-additonal-data ,site 'html-header (page-elements page-var))))

;;; html.lisp ends here
