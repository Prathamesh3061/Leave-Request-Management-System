CLASS lhc_employee DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setDefaultLeaveBalance FOR DETERMINE ON MODIFY
     importing keys FOR Employee~setDefaultLeaveBalance.

ENDCLASS.

CLASS lhc_employee IMPLEMENTATION.

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

CLASS lhc_leaverequest DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS calculateDuration FOR DETERMINE ON MODIFY
     importing keys FOR LeaveRequest~calculateDuration.

    METHODS setStatusToPending FOR DETERMINE ON MODIFY
     importing keys FOR LeaveRequest~setStatusToPending.

     METHODS updateLeaveBalance FOR DETERMINE ON MODIFY
      IMPORTING keys FOR LeaveRequest~updateLeaveBalance.

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



METHOD updateLeaveBalance.

    " 1. Read changed Leave Requests
    READ ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY LeaveRequest
        FIELDS ( EmpId NumberOfDays )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_leave_requests).

    CHECK lt_leave_requests IS NOT INITIAL.

    " 2. Read parent Employee instances via association
    READ ENTITIES OF y195_i_emp IN LOCAL MODE
      ENTITY LeaveRequest BY \_Employee
        FIELDS ( EmpId LeaveBalance )
        WITH VALUE #( FOR req IN lt_leave_requests ( %tky = req-%tky ) )
      RESULT DATA(lt_employees).

    " Avoid duplicate parent employee processing
    SORT lt_employees BY EmpId.
    DELETE ADJACENT DUPLICATES FROM lt_employees COMPARING EmpId.

    DATA lt_emp_update TYPE TABLE FOR UPDATE y195_i_emp\\Employee.

    " 3. Calculate new balance for each employee
    LOOP AT lt_employees INTO DATA(ls_emp).

      " Read all leave requests of this employee from the transactional/draft buffer
      READ ENTITIES OF y195_i_emp IN LOCAL MODE
        ENTITY Employee BY \_LeaveRequests
          FIELDS ( NumberOfDays Status )
          WITH VALUE #( ( %tky = ls_emp-%tky ) )
        RESULT DATA(lt_all_reqs).

      DATA lv_total_leave_taken TYPE p DECIMALS 1 VALUE '0.0'.
      LOOP AT lt_all_reqs INTO DATA(ls_req) WHERE Status <> 'REJECTED'.
        lv_total_leave_taken = lv_total_leave_taken + ls_req-NumberOfDays.
      ENDLOOP.

      " Compute remaining balance using explicitly typed variable
      DATA lv_calculated_balance TYPE p DECIMALS 1.
      lv_calculated_balance = '20.0' - lv_total_leave_taken.

      APPEND VALUE #(
        %tky                  = ls_emp-%tky
        LeaveBalance          = lv_calculated_balance
        %control-LeaveBalance = if_abap_behv=>mk-on
      ) TO lt_emp_update.

    ENDLOOP.

    " 4. Update the parent Employee buffer
    IF lt_emp_update IS NOT INITIAL.
      MODIFY ENTITIES OF y195_i_emp IN LOCAL MODE
        ENTITY Employee
          UPDATE FIELDS ( LeaveBalance )
          WITH lt_emp_update
        FAILED DATA(lt_failed).
    ENDIF.

  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

