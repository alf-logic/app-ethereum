"""Prompt templates for claude -p analysis calls."""

SPEC_GENERATION = """You are analyzing a C function to create a formal behavioral specification.

## Function Source
```c
{source}
```

## Task
Generate a Gherkin specification for the function `{function_name}`.

Follow this exact format:
```gherkin
@id-feat-{function_name}
Feature: {function_name}
  [Description of what the function does]

  @id-rule-[rule-name]
  Rule: [Rule description]
    * constraint: [Invariant]

    @id-scen-[scenario-name]
    @verified-by-unittest
    @unittest-name-test_{function_name}_[scenario]
    Scenario: [Description]
      Given [input state with concrete values]
      When {function_name} is called with [params]
      Then [expected result with concrete values]
```

Requirements:
- First, understand the MATHEMATICAL INTENT of the function (what it SHOULD do)
- Derive expected values from the math, NOT by tracing the code
- Cover ALL branches/paths including error/edge cases
- Include boundary conditions and adversarial inputs
- CRITICAL: Include scenarios that test common bug patterns:
  * What happens with zero inputs? (division by zero, null pointers)
  * What happens at type boundaries? (UINT32_MAX, UINT64_MAX)
  * What happens when arguments are in unexpected order? (divisor > dividend)
  * What happens with aliased pointers? (input == output)
- Each scenario must have concrete input/output values (hex for large numbers)
- Tag each scenario with @unittest-name matching test_{function_name}_[scenario]
- Use lowercase hyphen-separated identifiers for tags
- Do NOT include redundant scenarios that test the same code path

Output ONLY the gherkin block, no other text."""


TEST_GENERATION = """You are generating cmocka unit tests for a C function.

## Function Source
```c
{source}
```

## Gherkin Spec
```gherkin
{spec}
```

## Task
Generate a complete cmocka test file for `{function_name}` matching the Gherkin spec above.

IMPORTANT: Do NOT redefine types or macros that already exist in headers.
Do NOT include a header named after the function (e.g. NOT "{function_name}.h").
Include the SAME header the source file includes for its own declarations.

Look at the #include lines in the function source to determine the correct headers.

Follow this exact pattern:
```c
/**
 * @file test_{function_name}.c
 * @brief Unit tests for {function_name}() — linked to Gherkin specs
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

// Use these exact includes from the source file:
{includes}

static void test_{function_name}_[scenario](void **state) {{
    (void) state;
    // Arrange: set up inputs from Given step
    // Act: call function from When step
    // Assert: verify from Then step using assert_int_equal
}}

int main(void) {{
    const struct CMUnitTest tests[] = {{
        cmocka_unit_test(test_{function_name}_[scenario]),
    }};
    return cmocka_run_group_tests(tests, NULL, NULL);
}}
```

One test function per Gherkin scenario. Use the exact function names from @unittest-name tags.
The test values must match the Gherkin spec EXACTLY.
Output ONLY the complete C test file, no other text."""
