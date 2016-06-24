def transform_context(context)
  context.merge({
    :package_name => context[:module_name].downcase.gsub("-", "_")
  })
end
