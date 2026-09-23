@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: 'Value Help for Leave Types'
@ObjectModel.resultSet.sizeCategory: #XS

define view entity Y195_I_LEAVETYPE_VH
  as select from y195_leave_req
{
  @UI.textArrangement: #TEXT_ONLY
  key 'ANNUAL'  as LeaveType,
      'Annual Leave' as Description
}
union
select from y195_leave_req
{
  key 'SICK'    as LeaveType,
      'Sick Leave' as Description
}
union
select from y195_leave_req
{
  key 'CASUAL'  as LeaveType,
      'Casual Leave' as Description
}
union
select from y195_leave_req
{
  key 'UNPAID'  as LeaveType,
      'Unpaid Leave' as Description
}
