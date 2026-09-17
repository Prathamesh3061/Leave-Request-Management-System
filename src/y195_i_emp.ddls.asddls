@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Employee Master - Root Interface View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define root view entity Y195_I_EMP 
as select from y195_emp
composition [0..*] of Y195_I_LEAVE_REQ as _LeaveRequests
{
    key y195_emp.emp_id as EmpId,  
    y195_emp.emp_name as EmpName,
    y195_emp.department as Department,
    y195_emp.email as Email,
    y195_emp.joining_date as JoiningDate,
    
    @Semantics.quantity.unitOfMeasure: 'UnitOfMeasure'
    y195_emp.leave_balance as LeaveBalance,
    cast( 'DAYS' as abap.unit( 3 ) ) as UnitOfMeasure,
    
    @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt,
    
    _LeaveRequests // Make association public
}
