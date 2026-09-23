@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Leave Request - Projection View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity Y195_C_LEAVE_REQ 
as projection on Y195_I_LEAVE_REQ
{
    key ReqId,
      EmpId,
      
      @Consumption.valueHelpDefinition: [{ 
        entity: { 
          name: 'Y195_I_LEAVETYPE_VH', 
          element: 'LeaveType' 
        } 
      }]
      LeaveType,
      
      StartDate,
      EndDate,
      NumberOfDays,
      UnitOfMeasure,
      Reason,
      Status,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,

      /* Association Redirection */
      _Employee : redirected to parent Y195_C_EMP
}
