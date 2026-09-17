@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Leave Request - Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity Y195_I_LEAVE_REQ 
as select from Y195_LEAVE_REQ
association to parent Y195_I_EMP as _Employee
on $projection.EmpId = _Employee.EmpId
{
    key req_id as ReqId,
    emp_id as EmpId,
    leave_type as LeaveType,
    start_date as StartDate,
    end_date as EndDate,
    @Semantics.quantity.unitOfMeasure: 'UnitOfMeasure'
    number_of_days as NumberOfDays,
    cast( 'DAYS' as abap.unit( 3 ) ) as UnitOfMeasure,
    reason as Reason,
    status as Status,
    
    
// Administrative and Concurrency fields
      @Semantics.user.createdBy: true
      created_by      as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at      as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at as LastChangedAt,
    
    
    _Employee
}
