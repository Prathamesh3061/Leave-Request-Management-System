CLASS y195_cl_load_initial_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS y195_cl_load_initial_data IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
DATA: lt_emp       TYPE STANDARD TABLE OF y195_emp,
          lt_leave_req TYPE STANDARD TABLE OF y195_leave_req,
          lv_timestamp TYPE abp_creation_tstmpl.

    " Clear existing data to allow safe re-runs
    DELETE FROM y195_emp.
    DELETE FROM y195_leave_req.
    DELETE FROM y195_emp_d.
    DELETE FROM y195_leave_req_d.

    " Current UTC timestamp for audit fields
    GET TIME STAMP FIELD lv_timestamp.

    " -----------------------------------------------------------------------
    " 1. Prepare 10 Employee Master Records
    " -----------------------------------------------------------------------
    lt_emp = VALUE #(
      ( emp_id = '0000000101' emp_name = 'Sarah Connor'      department = 'Information Tech' email = 'sarah.connor@example.com'      joining_date = '20210315' leave_balance = '18.0' )
      ( emp_id = '0000000102' emp_name = 'Alan Turing'       department = 'Research & Dev'   email = 'alan.turing@example.com'       joining_date = '20200110' leave_balance = '14.5' )
      ( emp_id = '0000000103' emp_name = 'Ada Lovelace'      department = 'Software Eng'     email = 'ada.lovelace@example.com'      joining_date = '20200801' leave_balance = '21.0' )
      ( emp_id = '0000000104' emp_name = 'Grace Hopper'      department = 'DevOps & Cloud'   email = 'grace.hopper@example.com'      joining_date = '20191120' leave_balance = '12.0' )
      ( emp_id = '0000000105' emp_name = 'Linus Torvalds'    department = 'Core Platforms'   email = 'linus.torvalds@example.com'    joining_date = '20180512' leave_balance = '09.5' )
      ( emp_id = '0000000106' emp_name = 'Katherine Johnson' department = 'Data Analytics'   email = 'katherine.j@example.com'       joining_date = '20220201' leave_balance = '16.0' )
      ( emp_id = '0000000107' emp_name = 'Tim Berners-Lee'   department = 'Web Systems'      email = 'tim.bl@example.com'            joining_date = '20210719' leave_balance = '11.0' )
      ( emp_id = '0000000108' emp_name = 'Margaret Hamilton' department = 'Mission Critical' email = 'margaret.h@example.com'       joining_date = '20190410' leave_balance = '20.0' )
      ( emp_id = '0000000109' emp_name = 'Dennis Ritchie'    department = 'Systems Eng'      email = 'dennis.ritchie@example.com'    joining_date = '20170905' leave_balance = '07.5' )
      ( emp_id = '0000000110' emp_name = 'Hedy Lamarr'       department = 'Wireless & Comms' email = 'hedy.lamarr@example.com'       joining_date = '20230116' leave_balance = '22.0' )
    ).

    " -----------------------------------------------------------------------
    " 2. Prepare 10 Leave Request Records (Linked to Employees)
    " -----------------------------------------------------------------------
    lt_leave_req = VALUE #(
      ( req_id = cl_system_uuid=>create_uuid_x16_static( )
      emp_id = '0000000101' leave_type = 'ANNUAL' start_date = '20260401' end_date = '20260403'
      number_of_days = '3.0' reason = 'Family vacation'        status = 'APPROVED' created_by = sy-uname created_at = lv_timestamp
      last_changed_by = sy-uname last_changed_at = lv_timestamp )
      ( req_id = cl_system_uuid=>create_uuid_x16_static( )
      emp_id = '0000000101' leave_type = 'SICK'   start_date = '20260510' end_date = '20260510'
      number_of_days = '1.0' reason = 'Dentist appointment'   status = 'APPROVED' created_by = sy-uname created_at = lv_timestamp
      last_changed_by = sy-uname last_changed_at = lv_timestamp )
      ( req_id = cl_system_uuid=>create_uuid_x16_static( )
      emp_id = '0000000102' leave_type = 'ANNUAL' start_date = '20260615' end_date = '20260619'
      number_of_days = '5.0' reason = 'Summer break'           status = 'PENDING'  created_by = sy-uname created_at = lv_timestamp
      last_changed_by = sy-uname last_changed_at = lv_timestamp )
      ( req_id = cl_system_uuid=>create_uuid_x16_static( )
       emp_id = '0000000103' leave_type = 'CASUAL' start_date = '20260325' end_date = '20260325'
       number_of_days = '0.5' reason = 'Personal errand'        status = 'APPROVED' created_by = sy-uname created_at = lv_timestamp
       last_changed_by = sy-uname last_changed_at = lv_timestamp )
      ( req_id = cl_system_uuid=>create_uuid_x16_static( )
      emp_id = '0000000104' leave_type = 'SICK'   start_date = '20260211' end_date = '20260212'
      number_of_days = '2.0' reason = 'Flu symptoms'          status = 'REJECTED' created_by = sy-uname created_at = lv_timestamp
      last_changed_by = sy-uname last_changed_at = lv_timestamp )
      ( req_id = cl_system_uuid=>create_uuid_x16_static( )
       emp_id = '0000000105' leave_type = 'ANNUAL' start_date = '20260701' end_date = '20260705'
       number_of_days = '5.0' reason = 'Conference attendance'  status = 'PENDING'  created_by = sy-uname created_at = lv_timestamp
       last_changed_by = sy-uname last_changed_at = lv_timestamp )
      ( req_id = cl_system_uuid=>create_uuid_x16_static( )
      emp_id = '0000000106' leave_type = 'CASUAL' start_date = '20260420' end_date = '20260421'
      number_of_days = '2.0' reason = 'Relocation moving'     status = 'APPROVED' created_by = sy-uname created_at = lv_timestamp
      last_changed_by = sy-uname last_changed_at = lv_timestamp )
      ( req_id = cl_system_uuid=>create_uuid_x16_static( )
       emp_id = '0000000107' leave_type = 'SICK'   start_date = '20260812' end_date = '20260812'
       number_of_days = '1.0' reason = 'Routine checkup'       status = 'PENDING'  created_by = sy-uname created_at = lv_timestamp
       last_changed_by = sy-uname last_changed_at = lv_timestamp )
      ( req_id = cl_system_uuid=>create_uuid_x16_static( )
      emp_id = '0000000108' leave_type = 'ANNUAL' start_date = '20260901' end_date = '20260904'
      number_of_days = '4.0' reason = 'Family gathering'      status = 'APPROVED' created_by = sy-uname created_at = lv_timestamp
      last_changed_by = sy-uname last_changed_at = lv_timestamp )
      ( req_id = cl_system_uuid=>create_uuid_x16_static( )
      emp_id = '0000000109' leave_type = 'UNPAID' start_date = '20261015' end_date = '20261020'
      number_of_days = '6.0' reason = 'Extended leave'         status = 'PENDING'  created_by = sy-uname created_at = lv_timestamp
      last_changed_by = sy-uname last_changed_at = lv_timestamp )
    ).

    " -----------------------------------------------------------------------
    " 3. Insert and Output Status to Console
    " -----------------------------------------------------------------------
    INSERT y195_emp FROM TABLE @lt_emp.
    IF sy-subrc = 0.
      out->write( |Inserted { lines( lt_emp ) } records into Y195_EMP successfully.| ).
    ELSE.
      out->write( 'Error inserting into Y195_EMP.' ).
    ENDIF.

    INSERT y195_leave_req FROM TABLE @lt_leave_req.
    IF sy-subrc = 0.
      out->write( |Inserted { lines( lt_leave_req ) } records into Y195_LEAVE_REQ successfully.| ).
    ELSE.
      out->write( 'Error inserting into Y195_LEAVE_REQ.' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
