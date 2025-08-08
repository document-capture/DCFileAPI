permissionset 63060 "All"
{
    Access = Internal;
    Assignable = true;
    Caption = 'All permissions', Locked = true;

    Permissions =
         codeunit "DCADV File API Event Handler" = X,
         codeunit "DCADV File API Management" = X,
         codeunit "DCADV Http Management" = X,
         page "DCADV Split and Merge local" = X;
}