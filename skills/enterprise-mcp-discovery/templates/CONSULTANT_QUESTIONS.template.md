# Consultant questions — {{company}}

**Language:** {{locale}}. Default for Québec/French-first companies:
`fr-CA` and `en` together in every block. If the user asked for a single
language, use only that one.

## How to use this

Each block below is a stand-alone message. Copy the block for the software you
need, paste it into an email or Slack DM to the right person, and send it.
Each consultant is usually different, so the blocks are kept separate — do not
merge them.

When a block holds two languages, both paragraphs say the same thing. Send both
if you are not sure which language your consultant prefers.

---


{{#each system_blocks}}

## {{system_name}}
(send to: {{owner}})

> {{context_line}}
>
> {{ask_line}}

> `fr-CA` — {{context_line_fr}}
>
> {{ask_line_fr}}

> `en` — {{context_line_en}}
>
> {{ask_line_en}}

{{/each}}
