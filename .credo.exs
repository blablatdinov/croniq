%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Design.TagTODO, false},
        {Credo.Check.Readability.AliasOrder, false},
        {Credo.Check.Readability.ModuleNames, false}
      ]
    }
  ]
}
