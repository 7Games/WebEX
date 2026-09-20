;;; rss.lisp --- RSS Export template for WebEX

;;; Commentary:

;; For exporting WebEX format to RSS
;; Based off html.lisp

;;; Code:

;;;;;;;;;;;;;;;
;; Constants ;;
;;;;;;;;;;;;;;;

(defconstant *RSS-AUTHOR-EMAIL* "author@example.com")

;;;;;;;;;;;
;; hacky ;;
;;;;;;;;;;;

(defvar site-url "")

;;;;;;;;;;;;;
;; Helpers ;;
;;;;;;;;;;;;;

(defun rss--eval-element-list (elements)
  (let ((str ""))
    (loop for element in elements
          do (setf str (string-concat str (element-to-rss element))))
    str))

(defun rss--remove-spaces (str char)
  (join-string-list (string-split-by-delim str #\Space) char))

(defun rss--remove-newline (str char)
  (join-string-list (string-split-by-delim str #\Newline) char))

(defun rss--fixup-string (str)
  (string-downcase (rss--remove-spaces str "-")))

;;;;;;;;;;;;;;;;;;;;;;;;
;; WebEX to HTML tags ;;
;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric --element-to-rss (type element))

(defmethod --element-to-rss ((type (eql :heading)) element)
  (let* ((text (element-heading-content element)))
    (string-concat "<h1>" text "</h1>")))

(defmethod --element-to-rss ((type (eql :subheading)) element)
  (let* ((text (element-subheading-content element)))
    (string-concat "<h2>" text "</h2>")))

(defmethod --element-to-rss ((type (eql :paragraph)) element)
  (string-concat "<p>" (rss--eval-element-list (element-paragraph-elements element)) "</p>"))

(defmethod --element-to-rss ((type (eql :mixer)) element)
  (string-concat (rss--eval-element-list (element-mixer-elements element))))

(defmethod --element-to-rss ((type (eql :text)) element)
  (string-concat (element-text-content element)))

(defmethod --element-to-rss ((type (eql :link)) element)
  (string-concat "<a href=\"" (element-link-url element) "\">" (element-link-text element) "</a>"))

(defmethod --element-to-rss ((type (eql :list)) element)
  (let ((index 1)
        (str (make-array 0 :element-type 'character
                           :adjustable t
                           :fill-pointer t)))
    (loop for e in (car (element-list-elements element))
          do (progn
               (format str "<p> ~A ~A</p>~%" (if (eq (element-list-type element) :unordered) "-" (format nil "~d." index))
                       (element-to-rss e))
               (setq index (+ 1 index))))
    str))

(defmethod --element-to-rss ((type (eql :image)) element)
  (string-concat "<img src=\"" (string-concat site-url (element-image-file element)) "\" alt=\"" (element-image-alt element) "\"/>"))

(defmethod --element-to-rss ((type (eql :codeblock)) element)
  (string-concat "<p>== CODE =============<br /><b><i>" (rss--remove-newline (element-codeblock-content element) "<br />") "</i></b><br />====================</p>"))

(defmethod --element-to-rss ((type (eql :inline-codeblock)) element)
  (string-concat "<b><i>" (element-inline-codeblock-content element) "</i></b>"))

(defmethod --element-to-rss ((type (eql :newline)) element)
  (string-concat "<br />"))

(defmethod --element-to-rss ((type (eql :separator)) element)
  (string-concat "--------------------------"))

(defun element-to-rss (element)
  (if element (--element-to-rss (element-type element) element)))

;;;;;;;;;;;;
;; Export ;;
;;;;;;;;;;;;

;; Base RSS format based on https://www.w3schools.com/XML/xml_rss.asp
(defun export-to-rss (site rss-title rss-url rss-description website-url export-file)
  (ensure-directories-exist (get-file-root export-file))
  (format t "Exporting site to RSS...~%")
  (with-open-file (stream export-file
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (setq site-url website-url)
    (format stream "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>~%")
    (format stream "<rss version=\"2.0\">~%")
    (format stream "<channel>~%")
    (format stream "<title>~A</title>~%" rss-title)
    (format stream "<generator>WebEX RSS export</generator>~%")
    (format stream "<language>en-gb</language>~%")
    (format stream "<lastBuildDate>~A</lastBuildDate>~%" (get-timestamp-RFC822))
    (format stream "<link>~A</link>~%" rss-url)
    (format stream "<description>~A</description>~%" rss-description)
    (loop for page in (site-pages site)
          do (when page
               (format stream "<item>~%")
               (format stream "<title>~A</title>~%" (page-name page))
               (format stream "<pubDate>~A</pubDate>~%" (cdr (find-additonal-data page "blog-created")))
               ;; <guid>
               (format stream "<url>~A#~A</url>~%" rss-url (rss--fixup-string (string-concat (page-name page) " (" (cdr (find-additonal-data page "blog-created")) ")")))
               (format stream "<description>~%")
               (loop for e in (page-elements page)
                     do (format stream "~A~%" (element-to-rss e)))
               (format stream "</description>~%")
               (format stream "</item>~%")))
    (format stream "</channel>~%")
    (format stream "</rss>")
    (write-line "" stream))

  (format t "Site exported to ~A~%" export-file))

;;; rss.lisp ends here
