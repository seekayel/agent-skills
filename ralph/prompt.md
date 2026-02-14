## Start here
study `_specs/` (or `docs/` if `_specs/` doesn't exist) for design docs.
study `prd.json` for work items completed and those still to be worked on.

research additional information on the project in the _specs and docs directories.

Always research the code, run tests, and run the application to ensure it is in a good state and achieves its stated goals before making changes.

If the tests fail, the code research shows missing functionality, or the application doesn't completely work use that information in your priority decision.

Given the application that is described and the state of the research, pick the next most important issue in `prd.json` and implement it. Or if there are more important work items that are necessary for the application, based on your research that have not been added to `prd.json` add them and then pick one of them to work on.

If `prd.json` doesn't exist or everything is marked as done research and find what remains to be completed and add issues to `prd.json`.

## Process when code is done

Update `prd.json` when the issue is done. After completing an issue is it ok to add necessary additional work as issues to `prd.json`

1. Run the following, fixiing any errors and then trying the whole list again:
  - `npm run lint` for bun projects `bun run lint`
  - `npm run build` for bun projects `bun run build`
  - `npm run test` for bun projects `bun run test`
2. Add any missing tests to `prd.json` that need to be kept working.
3. Add important missing features to `prd.json` that are needed for application to meet its goals.
4. Commit changes.
5. Summarize changes and actions taken in 5-8 bullet points.
6. Return

## Front-end work
Whenever doing frontend/UI changes use your front-end skill to make sure the design and layout is good.

## prd.json example format

Status: [todo,inprogress,done,wontfix]
Priority: [critical,high,normal,low]

```json
{
  "project": "useful-cli-tool",
  "description": "CLI tool for doing things that are good https://github.com/useful/cli-tool",
  "issues": [
    {
      "id": 1,
      "title": "Proejct setup",
      "description": "A longer description of the things to setup.",
      "status": "todo",
      "priority": "critical"
    }
  ]
}
```