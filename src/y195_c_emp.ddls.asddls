@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Employee Master - Root Projection View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define root view entity Y195_C_EMP 
    provider contract transactional_query
    as projection on Y195_I_EMP
{
 @EndUserText.label: 'Employee ID'
key EmpId,
      EmpName,
      Department,
      Email,
      JoiningDate,
      LeaveBalance,
      UnitOfMeasure,
      
      LastChangedAt,

      /* Composition Redirection */
      _LeaveRequests : redirected to composition child Y195_C_LEAVE_REQ
}
