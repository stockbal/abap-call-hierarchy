"! <p class="shorttext synchronized" lang="en">Resource for ABAP Call Hierarchy</p>
CLASS zcl_acallh_adt_res_call_hier DEFINITION
  PUBLIC
  INHERITING FROM cl_adt_rest_resource
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS:
      get REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS:
      create_result
        IMPORTING
          root_comp_unit TYPE REF TO zif_acallh_abap_element
        RETURNING
          VALUE(result)  TYPE zif_acallh_ty_adt=>ty_call_hierarchy_result,

      convert_call_position
        IMPORTING
          call_position TYPE zif_acallh_ty_global=>ty_source_position
          uri           TYPE string
        RETURNING
          VALUE(result) TYPE zif_acallh_ty_adt=>ty_call_position.
ENDCLASS.



CLASS zcl_acallh_adt_res_call_hier IMPLEMENTATION.

  METHOD get.
    DATA hierarchy_result TYPE zif_acallh_ty_adt=>ty_call_hierarchy_result.

    DATA(uri) = zcl_acallh_adt_request_util=>get_query_parameter(
      param_name = zif_acallh_c_global=>c_call_hierarchy_params-uri
      mandatory  = abap_true
      request    = request ).

    DATA(root_comp_unit) = zcl_acallh_call_hierarchy=>get_abap_element_From_uri( uri ).
    IF root_comp_unit IS NOT INITIAL.
      hierarchy_result = create_result( root_comp_unit ).
      response->set_body_data(
        content_handler = zcl_acallh_ch_factory=>create_call_hier_result_ch( )
        data            = hierarchy_result ).
    ELSE.
      " raise exception???
    ENDIF.

  ENDMETHOD.


  METHOD create_result.
    DATA(called_units) = root_comp_unit->get_called_elements( ).

    DATA(root_uri) = root_comp_unit->get_call_position_uri( ).
    result = VALUE #(
      origin_type             = root_comp_unit->element_info-adt_type
      origin_object_name      = root_comp_unit->element_info-object_name
      origin_encl_object_name = root_comp_unit->element_info-encl_object_name
      entries                 = VALUE #(
      ( object_ref            = VALUE zif_acallh_ty_adt=>ty_adt_obj_ref(
          uri          = root_uri
          name         = root_comp_unit->element_info-object_name
          description  = root_comp_unit->element_info-description
          type         = root_comp_unit->element_info-adt_type )
        encl_obj_name         = root_comp_unit->element_info-encl_object_name
        encl_obj_display_name = root_comp_unit->element_info-encl_obj_display_name
        method_props          = root_comp_unit->element_info-method_props ) ) ).

    " fill the called units entries
    LOOP AT called_units INTO DATA(called_unit).
      DATA(call_positions) = VALUE zif_acallh_ty_adt=>ty_call_positions(
        FOR <callpos> IN called_unit->element_info-call_positions
        ( convert_call_position(
            call_position = <callpos>
            uri           = called_unit->get_call_position_uri( <callpos> ) ) ) ).

      result-entries = VALUE #( BASE result-entries
        ( object_ref            = VALUE zif_acallh_ty_adt=>ty_adt_obj_ref(
            uri          = call_positions[ 1 ]-uri
            parent_uri   = root_uri
            name         = called_unit->element_info-object_name
            description  = called_unit->element_info-description
            type         = called_unit->element_info-adt_type )
          encl_obj_name         = called_unit->element_info-encl_object_name
          encl_obj_display_name = called_unit->element_info-encl_obj_display_name
          method_props          = called_unit->element_info-method_props
          call_positions        = call_positions ) ).
    ENDLOOP.
  ENDMETHOD.


  METHOD convert_call_position.
    DATA(pos_in_uri) = zcl_acallh_adt_uri_util=>get_uri_source_start_pos( uri ).
    result = CORRESPONDING #( call_position ).
    result-uri = uri.
    result-line = pos_in_uri-line.
  ENDMETHOD.

ENDCLASS.