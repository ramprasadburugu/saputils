*&---------------------------------------------------------------------*
*& Report YRP_TABLE_COUNTS
*&
*&---------------------------------------------------------------------*
*& Program to get counts of records in SAP tables. Supports selection by
*& development package and table type
*&---------------------------------------------------------------------*
REPORT yrp_table_counts.

TABLES: dd02vv.

SELECT-OPTIONS s_table FOR dd02vv-tabname.
SELECT-OPTIONS s_appl FOR dd02vv-applclass.
SELECT-OPTIONS s_dlvc FOR dd02vv-contflag.

TYPES: BEGIN OF ty_out,
         tabname    TYPE tabname,
         ddlanguage TYPE ddlanguage,
         applclass  TYPE applclass,
         contflag   TYPE contflag,
         ddtext     TYPE ddtext,
         count(10)  TYPE c,
       END OF ty_out.

DATA gt_out TYPE TABLE OF ty_out.






START-OF-SELECTION.

  DATA lt_table TYPE STANDARD TABLE OF dd02vv.
  DATA ls_tab TYPE dd02vv.
  DATA ls_out TYPE ty_out.

  SELECT * FROM dd02vv INTO TABLE lt_table
         WHERE tabname IN s_table
           AND ddlanguage = sy-langu
           AND applclass IN s_appl
           AND contflag IN s_dlvc
           AND tabclass IN ('POOL', 'TRANSP').


  SORT lt_table BY contflag TABNAME.



  LOOP AT lt_table INTO ls_tab.
    AT NEW contflag.
      CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
        EXPORTING
         PERCENTAGE       = 10
          text = ls_tab-contflag.
      .

    ENDAT.

    CLEAR ls_out.
    MOVE-CORRESPONDING ls_tab TO ls_out.
    SELECT SINGLE COUNT(*) FROM (ls_out-tabname) INTO ls_out-count.
    APPEND ls_out TO gt_out.

  ENDLOOP.

  PERFORM display_alv.
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv .
  DATA:
    salv_table     TYPE REF TO cl_salv_table,
    salv_events    TYPE REF TO cl_salv_events,
    salv_functions TYPE REF TO cl_salv_functions_list,
    salv_msg       TYPE REF TO cx_salv_msg,
    salv_layout    TYPE REF TO cl_salv_layout,
    salv_key       TYPE        salv_s_layout_key,
    salv_columns   TYPE REF TO cl_salv_columns.

  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = salv_table
        CHANGING
          t_table      = gt_out ).

    CATCH cx_salv_msg INTO salv_msg.
*       Message zur Beendigung bei Fehler und Ausgabe am Screen
      MESSAGE salv_msg TYPE 'I' DISPLAY LIKE 'E'.
      EXIT.
  ENDTRY.

* Set screen status
*  salv_table->set_screen_status(
*    pfstatus      = 'STANDARD'
*    report        = sy-cprog
*    set_functions = salv_table->c_functions_all ).

* Set functions
  salv_functions = salv_table->get_functions( ).

  salv_functions->set_all( abap_true ).
  salv_functions->set_export_xml( abap_true ).
  salv_functions->set_view_lotus( abap_false ).
*  salv_functions->SET_COLUMN_OPTIMIZE( apab_true ).

* optimize columns
  salv_columns = salv_table->get_columns( ).

  salv_columns->set_optimize( abap_true ).

* Process layout
  salv_layout = salv_table->get_layout( ).

  salv_key-report = sy-cprog.
  salv_layout->set_key( salv_key ).
  salv_layout->set_default( abap_true ).
  salv_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).

* Register event
  salv_events = salv_table->get_event( ).
  "SET HANDLER on_user_command FOR salv_events.

* Display
  salv_table->display( ).
ENDFORM.

