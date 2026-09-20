(require "webex/webex.lisp")
(require "webex/export/html.lisp")

(create-site 'example "Example Site")

;; Copy over the files to the finished site
(add-static example "sites/example/static/style.css" "/style.css")
(add-static example "sites/example/static/thoth_and_khepri_from_the_papyrus_of_imenemsauf.jpg" "/image.jpg")

;;; Pages

;; Index

;;           [site]     [page name]   [page export file (w/o extension)]
(create-page example    "Index"       "/index"
             ;; Make sure we use the stylesheet
             (html-add-styling "/style.css")
             ;; Write our page
             (add-heading "This is an example!")
             (add-paragraph (create-text "\"Hey nice example site man!\" I hear you say."))
             (add-paragraph (create-text "And I thank you. This is a very cool and nice example site created using ")
                            (create-link "WebEX" "https://codeberg.org/svngms/WebEX"))
             (add-subheading "What can it do?")
             (add-paragraph (create-text "Well by default you can just export to HTML. But you can create your own export file to write the WebEX system into whatever format you want."))
             (add-link "Hey Click Me!" "/other-page/"))

;; Other page
(create-page example "Another page?" "/other-page/index"
             (html-add-styling "/style.css")
             (add-heading "ANOTHER PAGE!!! AND OTHER THINGS??")
             (add-paragraph (create-text "How about we just show you everything this can do?"))

             (add-subheading "Headings")
             (add-heading "This is a heading")
             (add-codeblock "(add-heading \"This is a heading\")")

             (add-subheading "Subheadings")
             (add-subheading "This is a subheading")
             (add-codeblock "(add-subheading \"This is a subheading\")")

             (add-subheading "Paragraphs")
             (add-paragraph (create-text "This is some text!"))
             (add-codeblock "(add-paragraph (create-text \"This is some text!\"))")

             (add-subheading "Links")
             (add-paragraph (create-text "Hey click this ")
                            (create-link "Link" "https://svngms.neocities.org/"))
             (add-codeblock "(add-paragraph (create-text \"Hey click this \")
               (create-link \"Link\" \"https://svngms.neocities.org/\"))")

             (add-subheading "List")
             (add-paragraph (create-text "Unordered"))
             (add-list :unordered (create-text "Item 1")
                                  (create-text "Item 2"))

             (add-paragraph (create-text "and ordered"))
             (add-list :ordered (create-text "Item 3")
                                (create-text "Item 4"))

             (add-codeblock "(add-list :unordered (create-text \"Item 1\")
                     (create-text \"Item 2\"))")
             (add-new-line)
             (add-codeblock "(add-list :ordered (create-text \"Item 3\")
                   (create-text \"Item 4\"))")

             (add-subheading "Image")
             (add-image "/image.jpg" "This is an image")
             (add-new-line)
             (add-new-line)
             (add-codeblock ";; You'll need to add the image as a static file
(add-static site \"sites/SITE/static/image.jpg\" \"/image.jpg\")
(add-image \"./image.jpg\" \"This is an image\")")

             (add-subheading "Separator")
             (add-paragraph (create-text "Some text"))
             (add-separator)
             (add-paragraph (create-text "Some more text"))
             (add-codeblock "(add-separator)")

             (add-subheading "Newline")
             (add-paragraph (create-text "I hope I don't get")
                            (create-new-line)
                            (create-text "cut in half"))
             (add-codeblock "(add-paragraph (create-text \"I hope I don't get\")
               (create-new-line)
               (create-text \"cut in half\"))")
             (add-paragraph (create-text "or"))
             (add-codeblock "(add-new-line)")

             (add-subheading "Mixer")
             (add-paragraph (create-text "Ok this system is great but not perfect, so sometime you need to hack something together to make stuff work. That's where the mixer comes in"))
             (add-list :unordered (create-text "Look at this item")
                       (create-mixer (list (create-text "And another")
                                           (create-list :unordered (list (create-text "Woah I'm a subitem?")))))
                       (create-text "Oh it's over :("))

             (add-codeblock "(add-list :unordered (create-text \"Look at this item\")
          (create-mixer (list (create-text \"And another\")
                              (create-list :unordered (list (create-text \"Woah I'm a subitem?\")))))
          (create-text \"Oh it's over :(\"))")

             (add-subheading "Codeblock")
             (add-codeblock "You've been seeing it all this time :)")
             (add-new-line)
             (add-codeblock "(add-codeblock \"You've been seeing it all this time :)\")")

             (add-subheading "Inline Codeblock")
             (add-paragraph (create-text "And you can also do ")
                            (create-inline-codeblock "this kind of stuff.")
                            (create-text " Cool right?"))
             (add-codeblock "(add-paragraph (create-text \"And you can also do \")
               (create-inline-codeblock \"this kind of stuff.\")
               (create-text \" Cool right?\"))"))

;;; Footer

(html-add-footer example
                 ;; Creates a horizontal bar seperator
                 (add-separator)
                 (add-paragraph (create-text "Date exported: ") (create-text (get-timestamp))) ;; (get-timestamp) returns the current date and time in YYYY-MM-DD hh:mm:ss format
                 (add-paragraph (create-text "Exported using ") (create-link "WebEx" "https://codeberg.org/svngms/webex")))

;;; Export

(export-to-html example)
