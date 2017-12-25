# Query language

`QUERY` syntax is as follows: `EXPRESSION [QUERY_OPERATOR QUERY]`.

`QUERY_OPERATOR` possible values are:
1. `AND`,
2. `OR`.

`EXPRESSION` syntax is as follows: `KEY EXPRESSION_OPERATOR VALUE`.

`KEY` possible values are:
1. Custom string starting with `[a-zA-Z]` and containing `[a-zA-Z0-9_\-\.]`,
2. `*` corresponding to any key.

Please note there is also a special shortcut for a `label` key: you can use `~` instead of `label.` (i.e. `~component` is equal to `label.component`).

`EXPRESSION_OPERATOR` possible values are:
1. `=`, `!=` (equality) is used for string (`string_fields`) and numerical (`number_fields`) values. If `VALUE` is in quotes, only string values will be considered. If `VALUE` has `%` or `_` characters, `LIKE` is used for comparison.
2. `>`, `<`, `>=`, `<=` (comparison) is used for numerical values only.
3. `=~`, `!~` (regular expression) is used for string values only. `MATCH` is used for comparison. `!~` search entries that **does not match** regular expression.
4. `is true`, `is false` is used for boolean values (`boolean_fields`) only.
5. `is null`, `is not null` is used to match a key having corresponding value in NULL values (`null_fields`).

P.S. All built-in operators (`is true`, `is null`, etc) are case insensitive. There may be spaces before and after operators.

## Examples
1.  `host=kube-1 and log.level > 10`
1.  `* =~ kube-[1-9]`
1.  `log !~ warning`
1.  `~component = clickhouse`
1.  `log = %error% or log != %success%`
1.  `unhealthy is true`
1.  `status is null`
