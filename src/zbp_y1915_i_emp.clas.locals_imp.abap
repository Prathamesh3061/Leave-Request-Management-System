CLASS lhc_employee DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setDefaultLeaveBalance FOR DETERMINE ON MODIFY
     importing keys FOR Employee~setDefaultLeaveBalance.

      METHODS validateEmail FOR VALIDATE ON SAVE
      IMPORTING keys FOR Employee~validateEmail.

      METHODS validateBalanceNotNegative FOR VALIDATE ON SAVE
      IMPORTING keys FOR Employee~validateBalanceNotNegative.

ENDCLASS.

CLASS lhc_employee IMPLEMENTATION.

*validate email format

    METHOD validateEmail.

        READ ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY Employee
        FIELDS ( Email )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_employees).

    LOOP AT lt_employees INTO DATA(ls_emp).
      IF ls_emp-Email IS NOT INITIAL.
        " Trim any trailing or leading whitespace
        DATA(lv_email) = condense( to_lower( ls_emp-Email ) ).

        " Modern PCRE regex supported cleanly in ABAP Cloud
        FIND PCRE '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$' IN lv_email.

        IF sy-subrc <> 0.
          " Mark the instance as failed to prevent save
          APPEND VALUE #(
            %tky = ls_emp-%tky
          ) TO failed-employee.

          " Report error message bound to the Email field on the UI
          APPEND VALUE #(
            %tky                = ls_emp-%tky
            %msg                = new_message_with_text(
                                    severity = if_abap_behv_message=>severity-error
                                    text     = 'Invalid email format. Must be formatted as name@domain.com'
                                  )
            %element-Email      = if_abap_behv=>mk-on
          ) TO reported-employee.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


*  balance is not negative

METHOD validateBalanceNotNegative.

    READ ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY Employee
        FIELDS ( LeaveBalance )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_employees).

    LOOP AT lt_employees INTO DATA(ls_emp).
      " If leave deductions push the remaining balance below zero
      IF ls_emp-LeaveBalance < 0.
        APPEND VALUE #(
          %tky = ls_emp-%tky
        ) TO failed-employee.

        APPEND VALUE #(
          %tky                   = ls_emp-%tky
          %msg                   = new_message_with_text(
                                     severity = if_abap_behv_message=>severity-error
                                     text     = 'Insufficient leave balance. Total requested leaves exceed available quota.'
                                   )
          %element-LeaveBalance  = if_abap_behv=>mk-on
        ) TO reported-employee.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


*default leave balance
  METHOD setDefaultLeaveBalance.
    " Read created Employee instances
    READ ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY Employee
        FIELDS ( LeaveBalance )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_employees).

    " Filter out employees that already have a balance entered
    DELETE lt_employees WHERE LeaveBalance IS NOT INITIAL.
    CHECK lt_employees IS NOT INITIAL.

    " Assign default quota of 20.0 days
    MODIFY ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY Employee
        UPDATE FIELDS ( LeaveBalance )
        WITH VALUE #( FOR emp IN lt_employees (
                        %tky                  = emp-%tky
                        LeaveBalance          = '20.0'
                        %control-LeaveBalance = if_abap_behv=>mk-on
                     ) )
      FAILED DATA(lt_failed).
  ENDMETHOD.

ENDCLASS.

*leaverequest

CLASS lhc_leaverequest DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS calculateDuration FOR DETERMINE ON MODIFY
     importing keys FOR LeaveRequest~calculateDuration.

    METHODS setStatusToPending FOR DETERMINE ON MODIFY
     importing keys FOR LeaveRequest~setStatusToPending.

     METHODS updateLeaveBalance FOR DETERMINE ON MODIFY
      IMPORTING keys FOR LeaveRequest~updateLeaveBalance.

      METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR LeaveRequest~validateDates.

    METHODS validateMandatoryFields FOR VALIDATE ON SAVE
      IMPORTING keys FOR LeaveRequest~validateMandatoryFields.

    METHODS validateOverlappingLeaves FOR VALIDATE ON SAVE
      IMPORTING keys FOR LeaveRequest~validateOverlappingLeaves.

ENDCLASS.

CLASS lhc_leaverequest IMPLEMENTATION.

*status pending
  METHOD setStatusToPending.
READ ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY LeaveRequest
        FIELDS ( Status )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_leave_requests).

    DELETE lt_leave_requests WHERE Status IS NOT INITIAL.
    CHECK lt_leave_requests IS NOT INITIAL.

    MODIFY ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY LeaveRequest
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR req IN lt_leave_requests (
                        %tky                  = req-%tky
                        Status                = 'PENDING'
                        %control-Status       = if_abap_behv=>mk-on
                     ) )
      FAILED DATA(lt_failed).
  ENDMETHOD.

*  calculateduration

  METHOD calculateDuration.
     READ ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY LeaveRequest
        FIELDS ( StartDate EndDate )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_leave_requests).

    DATA lt_update TYPE TABLE FOR UPDATE y195_i_emp\\LeaveRequest.

    LOOP AT lt_leave_requests INTO DATA(ls_req).
      IF ls_req-StartDate IS NOT INITIAL AND ls_req-EndDate IS NOT INITIAL.
        IF ls_req-EndDate >= ls_req-StartDate.
          DATA(lv_days) = ( ls_req-EndDate - ls_req-StartDate ) + 1.

          APPEND VALUE #(
            %tky                  = ls_req-%tky
            NumberOfDays          = lv_days
            %control-NumberOfDays = if_abap_behv=>mk-on
          ) TO lt_update.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF y195_i_emp IN LOCAL MODE
        ENTITY LeaveRequest
          UPDATE FIELDS ( NumberOfDays )
          WITH lt_update
        FAILED DATA(lt_failed).
    ENDIF.
  ENDMETHOD.

*update leave balance delte update create

METHOD updateLeaveBalance.

    DATA lt_employee_keys TYPE TABLE FOR READ IMPORT y195_i_emp\\Employee.

    " Try reading parent employee via association (works for Create and Modify)
    READ ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY LeaveRequest BY \_Employee
        FIELDS ( EmpId LeaveBalance )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_employees_assoc).

    IF lt_employees_assoc IS NOT INITIAL.
      lt_employee_keys = CORRESPONDING #( lt_employees_assoc ).
    ELSE.
      " During DELETE, child is already unlinked in buffer.
      " Extract parent EmpId directly from the draft table or remaining active requests
      LOOP AT keys INTO DATA(ls_key).
        SELECT SINGLE empid
          FROM y195_leave_req_d
          WHERE reqid = @ls_key-ReqId
          INTO @DATA(lv_empid_d).

        IF sy-subrc = 0.
          APPEND VALUE #( EmpId = lv_empid_d %is_draft = ls_key-%is_draft ) TO lt_employee_keys.
        ELSE.
          SELECT SINGLE emp_id
            FROM y195_leave_req
            WHERE req_id = @ls_key-ReqId
            INTO @DATA(lv_empid_act).
          IF sy-subrc = 0.
            APPEND VALUE #( EmpId = lv_empid_act %is_draft = ls_key-%is_draft ) TO lt_employee_keys.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SORT lt_employee_keys BY EmpId.
    DELETE ADJACENT DUPLICATES FROM lt_employee_keys COMPARING EmpId.
    CHECK lt_employee_keys IS NOT INITIAL.

    DATA lt_emp_update TYPE TABLE FOR UPDATE y195_i_emp\\Employee.

    " Recalculate remaining quota for each affected employee
    LOOP AT lt_employee_keys INTO DATA(ls_emp_key).

      " Read all remaining leave requests for this employee from transactional buffer
      READ ENTITIES OF y195_i_emp IN LOCAL MODE
        ENTITY Employee BY \_LeaveRequests
          FIELDS ( NumberOfDays Status )
          WITH VALUE #( ( %tky = ls_emp_key-%tky ) )
        RESULT DATA(lt_all_reqs).

      DATA lv_total_leave_taken TYPE p DECIMALS 1 VALUE '0.0'.
      LOOP AT lt_all_reqs INTO DATA(ls_req) WHERE Status <> 'REJECTED'.
        lv_total_leave_taken = lv_total_leave_taken + ls_req-NumberOfDays.
      ENDLOOP.

      DATA lv_calculated_balance TYPE p DECIMALS 1.
      lv_calculated_balance = '20.0' - lv_total_leave_taken.

      APPEND VALUE #(
        %tky                  = ls_emp_key-%tky
        LeaveBalance          = lv_calculated_balance
        %control-LeaveBalance = if_abap_behv=>mk-on
      ) TO lt_emp_update.

    ENDLOOP.

    IF lt_emp_update IS NOT INITIAL.
      MODIFY ENTITIES OF y195_i_emp IN LOCAL MODE
        ENTITY Employee
          UPDATE FIELDS ( LeaveBalance )
          WITH lt_emp_update
        FAILED DATA(lt_failed).
    ENDIF.

  ENDMETHOD.

*  validation date rules
    METHOD validateDates.

    READ ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY LeaveRequest
        FIELDS ( StartDate EndDate )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_leave_requests).

    READ ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY LeaveRequest BY \_Employee
        FIELDS ( JoiningDate )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_employees).

    LOOP AT lt_leave_requests INTO DATA(ls_req).

      " A. Chronological order check
      IF ls_req-EndDate < ls_req-StartDate.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-leaverequest.
        APPEND VALUE #(
          %tky             = ls_req-%tky
          %element-EndDate = if_abap_behv=>mk-on
          %msg             = new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = 'End Date cannot be before Start Date.'
                             )
        ) TO reported-leaverequest.
      ENDIF.

      " B. Past date check
      IF ls_req-StartDate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-leaverequest.
        APPEND VALUE #(
          %tky               = ls_req-%tky
          %element-StartDate = if_abap_behv=>mk-on
          %msg               = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Cannot request leave in the past.'
                               )
        ) TO reported-leaverequest.
      ENDIF.

      " C. Joining date check
      READ TABLE lt_employees INTO DATA(ls_emp) INDEX 1.
      IF sy-subrc = 0 AND ls_emp-JoiningDate IS NOT INITIAL.
        IF ls_req-StartDate < ls_emp-JoiningDate.
          APPEND VALUE #( %tky = ls_req-%tky ) TO failed-leaverequest.
          APPEND VALUE #(
            %tky               = ls_req-%tky
            %element-StartDate = if_abap_behv=>mk-on
            %msg               = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = 'Start Date cannot be earlier than Employee Joining Date.'
                                 )
          ) TO reported-leaverequest.
        ENDIF.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

*  validation mandatory fields
    METHOD validateMandatoryFields.

    READ ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY LeaveRequest
        FIELDS ( LeaveType StartDate EndDate )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_leave_requests).

    LOOP AT lt_leave_requests INTO DATA(ls_req).

      IF ls_req-LeaveType IS INITIAL.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-leaverequest.
        APPEND VALUE #(
          %tky               = ls_req-%tky
          %element-LeaveType = if_abap_behv=>mk-on
          %msg               = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Leave Type is mandatory.'
                               )
        ) TO reported-leaverequest.
      ENDIF.

      IF ls_req-StartDate IS INITIAL.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-leaverequest.
        APPEND VALUE #(
          %tky               = ls_req-%tky
          %element-StartDate = if_abap_behv=>mk-on
          %msg               = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Start Date is mandatory.'
                               )
        ) TO reported-leaverequest.
      ENDIF.

      IF ls_req-EndDate IS INITIAL.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-leaverequest.
        APPEND VALUE #(
          %tky             = ls_req-%tky
          %element-EndDate = if_abap_behv=>mk-on
          %msg             = new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = 'End Date is mandatory.'
                             )
        ) TO reported-leaverequest.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

*  validation overlaping leaves check
    METHOD validateOverlappingLeaves.

    READ ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY LeaveRequest
        FIELDS ( ReqId EmpId StartDate EndDate )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_leave_requests).

    LOOP AT lt_leave_requests INTO DATA(ls_req).
      CHECK ls_req-StartDate IS NOT INITIAL AND ls_req-EndDate IS NOT INITIAL.

      " Read sibling leave requests for this employee from transactional buffer
      READ ENTITIES OF y195_i_emp IN LOCAL MODE
        ENTITY LeaveRequest BY \_Employee
          FIELDS ( EmpId )
          WITH VALUE #( ( %tky = ls_req-%tky ) )
        RESULT DATA(lt_emp).

      CHECK lt_emp IS NOT INITIAL.

      READ ENTITIES OF y195_i_emp IN LOCAL MODE
        ENTITY Employee BY \_LeaveRequests
          FIELDS ( ReqId StartDate EndDate Status )
          WITH VALUE #( ( %tky = lt_emp[ 1 ]-%tky ) )
        RESULT DATA(lt_siblings).

      " Check if any other request collides with this date window
      LOOP AT lt_siblings INTO DATA(ls_other)
        WHERE ReqId <> ls_req-ReqId
          AND Status <> 'REJECTED'.

        " Interval overlap logic: StartA <= EndB AND EndA >= StartB
        IF ls_req-StartDate <= ls_other-EndDate AND ls_req-EndDate >= ls_other-StartDate.
          APPEND VALUE #( %tky = ls_req-%tky ) TO failed-leaverequest.
          APPEND VALUE #(
            %tky               = ls_req-%tky
            %element-StartDate = if_abap_behv=>mk-on
            %element-EndDate   = if_abap_behv=>mk-on
            %msg               = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = 'Leave dates overlap with another active leave request.'
                                 )
          ) TO reported-leaverequest.
          EXIT.
        ENDIF.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

