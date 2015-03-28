define ['./utils'], (utils) ->

  # Tooltips defined here, in one place. These are the HTML "title" attributes
  # that are transformed into jQueryUI tooltips. Consolidating them here is
  # good for future translation/localization, etc.
  #
  # This module returns a function that, when passed in a "dot notation" string
  # will return the appropriate tooltip function (or a default one, if the
  # requested tooltip does not exist. For example, to get the tooltip for the
  # syntactic category field of OLD forms:
  #
  #   tooltips('old.forms.syntactic_category')() #
  #
  # Some tooltips are functions that take an `options` argument. These functions
  # (generally) expect a `options.value` attribute that is the value of the
  # item being "tooltipped". Thus, if you pass a `Date` instance to the
  # `dateElicited` tooltip function, it will be used in the returned tooltip:
  #
  #   tooltips('fieldDB.forms.dateEntered') value: new Date()

  dateElicited =
    eng: (options) ->
      if options.value
        "This form was elicited on #{utils.humanDate options.value}"
      else
        'The date this form was elicited'

  tooltips =

    fieldDB:

      forms:

        dateElicited: dateElicited

        dateEntered:
          eng: (options) ->
            "This form was entered on #{utils.humanDatetime options.value}"

        dateModified:
          eng: (options) ->
            "This form was last modified on #{utils.humanDatetime options.value}"

        id:
          eng: "A unique identifier for this form (a UUID)."

        comments:
          eng: "Any user with the “commenter” role may add comments to a form.
            The date and time the comment was made and the commenter are
            automatically saved when a comment is created."

          text:
            eng: "The content of the comment."

    old:

      subcorpora:

        name:
          eng: "A name for the subcorpus. Each subcorpus must have a name and
            it must be unique among subcorpora."

        description:
          eng: "A description of the subcorpus."

        content:
          eng: "The content of the subcorpus: a block of text containing
            references to the forms that constitute the content of the
            subcorpus."

        tags:
          eng: "Tags for categorizing subcorpora. (These are the same tags that
            are used throughout an OLD application; i.e., the same tag can be
            used to categorize a form and a subcorpus.)"

        form_search:
          eng: "An OLD form search object which defines the set of forms that
            constitute the subcorpus."

        id:
          eng: "The id of the subcorpus. This is an integer generated by the
          relational database that is used by the OLD. This value can be used
          to uniquely identify the subcorpus."

        UUID:
          eng: "The UUID (universally unique identifier) of the subcorpus. This
            is a unique value generated by the OLD. It is used to create
            references between subcorpora and their previous versions."

        enterer:
          eng: "The OLD user who entered/created the subcorpus. This value is
            specified automatically by the application."

        modifier:
          eng: "The OLD user who made the most recent modification to this
            subcorpus. This value is specified automatically by the
            application."

        datetime_entered:
          eng: (options) ->
            "This subcorpus was entered on #{utils.humanDatetime options.value}"

        datetime_modified:
          eng: (options) ->
            "This subcorpus was last modified on
              #{utils.humanDatetime options.value}"

        files:
          eng: "A list of files associated with this subcorpus. These are binary
            representations of the corpus in various formats, e.g., NLTK-style
            corpora or PTB-style treebanks. (TODO: verify this!)"

      forms:

        grammaticality:
          eng: "The grammaticality of the form, e.g., grammatical, ungrammatical,
            questionable, infelicitous in a given context. In the OLD,
            grammaticality is a forced-choice field and possible grammaticality
            values are defined on a database-wide setting."

        syntactic_category_string:
          eng: "A sequence of categories and morpheme delimiters (a sequence of
            parts-of-speech) corresponding to the morphological composition of
            the words in the form. If the form is mono-morphemic, then this
            value should be the same as the syntactic category value. The
            syntactic category string value is generated by the OLD based on
            the morpheme break and morpheme gloss values supplied by the user
            and the syntactic category of the morphemes implicit in those
            values. If, for example, a form has a morpheme break value of
            “chien-s” and a morpheme gloss value of “dog-PL”, and if
            the database contains lexical entries for “chien/dog” and
            “s/PL” with categories “N” and “Num”, respectively,
            then the syntactic category string value generated will be
            “N-Num”. Note that the OLD does not allow the syntactic
            category string to be explicitly defined by the user; this is by
            design: the idea is to encourage you to build a lexicon, a
            verbicon, a phrasicon, and a text collection simultaneously. You
            get more accurate syntactic category strings by increasing the
            consistency between your lexicon of morphemes and your lexicon of
            morphologically analyzed phrase-level forms."

        syntactic_category:
          eng: "The syntactic category of the form. Some examples: “N”,
            “S”, “Phi”, “Asp”, “JJ”, etc."

        comments:
          eng: "General-purpose field for notes and commentary about the form."

        speaker_comments:
          eng: "Field specifically for comments about the form made by the
            speaker-consultant."

        elicitation_method:
          eng: "How the form was elicited. Examples: “volunteered”,
            “judged elicitor’s utterance”, “translation task”, etc."

        tags:
          eng: "Tags for categorizing your forms. Note that the tags “foreign
            word” and “restricted” have special meaning in the OLD."

        speaker:
          eng: "The speaker (consultant) who produced or judged the form."

        elicitor:
          eng: "The linguistic fieldworker who elicited the form with the help
            of the consultant."

        enterer:
          eng: "The OLD user who entered/created the form. This value is
            specified automatically by the application."

        modifier:
          eng: "The OLD user who made the most recent modification to this
            form. This value is specified automatically by the application."

        verifier:
          eng: "The OLD user who has verified the reliability/accuracy of
            this form."

        source:
          eng: "The textual source (e.g., research paper, text collection, book
            of learning materials) from which the form was drawn, if applicable.
            Note that the OLD uses the BibTeX reference format for storing
            source information."

        files:
          eng: "The names of any files (e.g., audio, video, image or text
            files) that are associated to this form."

        collections:
          eng: "The titles of any OLD collections (e.g., papers, elicitation
            records, pedagogical materials) that this form is referenced in."

        break_gloss_category:
          eng: "The break/gloss/category value is generated by the
            OLD based on the morpheme break and morpheme gloss values and the
            (also auto-generated) syntactic category string value. The
            break/gloss/category value is a serialization of these three values. A
            form with “chien-s” as morpheme break, “dog-PL” as morpheme
            gloss and “N-Num” as category string will have
            “chien|dog|N-s|PL|Num” as its break/gloss/category value. This
            value is useful for search since it allows one to search through forms
            according to exactly specified morphemes."

        date_elicited: dateElicited

        datetime_entered:
          eng: (options) ->
            "This form was entered on #{utils.humanDatetime options.value}"

        datetime_modified:
          eng: (options) ->
            "This form was last modified on #{utils.humanDatetime options.value}"

        syntax:
          eng: "A syntactic phrase structure representation in some kind of
            string-based format. The OLD assumes that this will be a tree in
            bracket notation using Penn Treebank conventions."

        semantics:
          eng: "A semantic representation of the meaning of the form in some
            string-based format."

        status:
          eng: "The status of the form. This is used to indicate whether the form
          represents tested/verified data or whether it is a fieldworker-crafted form
          that requires testing. The OLD only allows two values for status:
          “tested” and “requires testing”."

        UUID:
          eng: "The UUID (universally unique identifier) of the form. This is a
            unique value generated by the OLD. It is used to create references
            between forms and their previous versions."

        id:
          eng: "The id of the form. This is an integer generated by the
          relational database that is used by the OLD. This value can be used
          to uniquely identify the form."

        narrow_phonetic_transcription:
          eng: "A narrow phonetic transcription, probably in IPA."

        phonetic_transcription:
          eng: "A phonetic transcription, probably in IPA."

        transcription:
          eng: "A transcription, probably orthographic."

        morpheme_break:
          eng: "A sequence of morpheme shapes and delimiters. The OLD assumes
            phonemic shapes (e.g., “in-perfect”), but phonetic (i.e.,
            allomorphic, e.g., “im-perfect”) ones are ok."

        morpheme_gloss:
          eng: "A sequence of morpheme glosses and delimiters, isomorphic to
          the morpheme break sequence, e.g., “NEG-parfait”."

        translations:
          eng: "Translations for the form. The OLD interface and data structure
            allow for any number of translations. Each translation may have its
            own grammaticality/acceptibility specification. Thus a translation that
            is ungrammatical in the metalanguage may be marked with “*” and one
            which is grammatical in the metalanguage but which is incongruous with
            the object language form may have an acceptibility value of “#”."

          transcription:
            eng: "A transcription of a possible translation of this form (in
              the metalanguage, the language of analysis)."

          # Note: this should be changed to "appropriateness" in the OLD.
          grammaticality:
            eng: "The appropriateness of this translation for this form."

  # This is the anonymous function that we return. It returns a second function
  # which returns the tooltip string when called. You use "dot notation" to get
  # the tooltip, e.g., `tooltips('old.forms.syntactic_category')()`.
  (namespace) ->
    parts = namespace.split '.'
    current = tooltips
    for part, index in parts
      if current[part]
        current = current[part]
      else
        current = {}
        break

    (options) ->
      language = options?.language or 'eng'
      if language of current
        tooltip = current[language]
      else if 'eng' of current
        tooltip = current.eng
      else
        tooltip = 'No tooltip.'
      if utils.type(tooltip) is 'function'
        tooltip options
      else
        tooltip

