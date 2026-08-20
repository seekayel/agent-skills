---
name: unslop
description: "Cut AI tells from any writing and rewrite in a direct, conversational voice. Use on any prose the agent produces or edits: blog posts, docs, READMEs, commit messages, emails. Triggers on: unslop this, humanize this, make this sound less like AI, remove AI tells, fix the writing, make it sound like me."
---

# Unslop

Edit text so it reads like a person wrote it. A specific person. Not a committee, not a chatbot, not a press release.

Adapted from the `unslop` skill in [cursor/plugins](https://github.com/cursor/plugins/tree/main/pstack/skills/unslop) (pstack). The pattern catalog is theirs. The voice is ours.

## The job

1. Scan for the patterns below.
2. Rewrite. Keep the meaning. Match the intended tone.
3. Apply the voice (next section).
4. Self-audit: "What makes this obviously AI generated?" Fix what's left.

Do all four steps. All four. The pattern scan alone gets you sterile prose that's just as obvious as the slop was.

## The voice

Calibrate to the writing style of [kamlasater.com/blog](https://kamlasater.com/blog). Here's what that means in practice:

- **Open with the point.** No throat clearing. "Several friends have asked me how to learn AI. Here's my honest answer: start using it." The answer is in sentence two, not paragraph four.
- **Give direct commands.** "Don't cheap out here." "Read the output." Not "it is recommended that users consider."
- **Repeat on purpose, and own it.** "Read the output. Read the output. I said it twice on purpose." Deliberate repetition beats a bold warning box.
- **Use first person.** "I'm talking the $100+ tier." "My recommendation." Personal experience over abstract expertise.
- **Ask real questions.** "I don't care what my assembly looks like, why should I care what my javascript looks like?" A rhetorical question that does actual work is worth ten hedged claims.
- **Use fragments for emphasis.** For anything. And everything. Short phrases create momentum.
- **Vary the rhythm.** Short sentences. Then longer ones that take their time and let an idea unfold before snapping back.
- **Have opinions, hold them loosely.** State the take plainly, then explore it. "This feels like new behavior." Confident yet curious, not pronouncing verdicts.
- **Be concrete.** Not "a paid tier" but "the $100+ tier from OpenAI, Anthropic, or Google." Numbers and names over categories.
- **Let some mess in.** Perfect structure looks machine-made. A tangent or an aside is fine if it earns its place.
- **Sentence case headings.** Plain words. No decoration.

## Patterns to detect and fix

### Content

1. **Puffery.** "pivotal moment", "testament to", "evolving landscape", "setting the stage for", "indelible mark", "deeply rooted". Cut it. State what happened.
2. **Name-dropping.** Listing media outlets without context. Pick one, say what was said.
3. **Superficial -ing phrases.** "highlighting...", "ensuring...", "reflecting...", "showcasing...", "fostering...". Delete or expand with real sources.
4. **Promotional language.** "nestled", "vibrant", "breathtaking", "groundbreaking", "renowned", "stunning", "must-visit". Use neutral descriptions.
5. **Vague attributions.** "Experts believe", "Industry reports suggest", "Some critics argue". Name the source or delete.
6. **Formulaic challenges.** "Despite challenges... continues to thrive." Replace with specific facts.

### Language

7. **AI vocabulary.** Additionally, crucial, delve, enduring, enhance, fostering, garner, interplay, intricate, landscape (abstract), pivotal, showcase, tapestry (abstract), testament, underscore, vibrant. Replace with plain words.
8. **Fancy ways to say "is".** "serves as", "stands as", "boasts", "features". Just say "is" or "has".
9. **"Not just X, but Y."** State the point directly instead.
10. **Rule of three.** Forcing ideas into groups of three. Use the natural number.
11. **Synonym cycling.** Protagonist, main character, central figure, hero all in one paragraph. Pick one, repeat it.
12. **False ranges.** "from X to Y" where X and Y aren't on a meaningful scale. List the topics directly.

### Style

13. **Em dash overuse.** Avoid em dashes entirely. Use periods or commas only (no parentheses standing in, no en dashes, no hyphens playing dash). If a thought needs separation, end the sentence.
14. **Colon overuse.** Colons are fine before a list or example. Not as mid-sentence connectors. Rewrite so the point stands on its own.
15. **Boldface overuse.** Don't bold every proper noun or acronym.
16. **Inline-header lists.** The tell is a bold label and colon that restates the line: "**Performance:** Performance improved...". Convert to prose. A bold lead-in that ends in a period and is followed by genuinely new detail is fine.
17. **Title case headings.** Use sentence case.
18. **Decorative emojis.** Remove from headings and bullets.
19. **Curly quotes.** Replace with straight quotes.

### Communication artifacts

20. **Chatbot phrases.** "I hope this helps!", "Let me know if...", "Of course!", "Certainly!", "Found the smoking gun!" Remove.
21. **Cutoff disclaimers.** "While specific details are limited..." Find sources or remove.
22. **Sycophantic tone.** "Great question! You're absolutely right!" Respond directly.

### Filler

23. **Filler phrases.** "In order to" becomes "To". "Due to the fact that" becomes "Because". "It is important to note that" gets deleted.
24. **Excessive hedging.** "could potentially possibly be argued that it might" becomes "may".
25. **Generic conclusions.** "The future looks bright." State specific plans or facts.

### Jargon

26. **Abstract metaphor nouns.** Substrate, wedge, vector, locus, vantage, nexus, primitive (as noun), harness (as metaphor), surface (as in "API surface"), bedrock, scaffolding (as metaphor), modality, paradigm, gold-plating, ratchet (as metaphor), evacuate (for moving code), endgame, north star, flywheel. These read as technical but usually have a plainer concrete word. "Substrate" becomes "base". "Wedge in" becomes "add". "Vector" becomes "way". "Endgame" becomes "the last phase". Pick the concrete word.

### Plain speech

27. **Say what it does, not how it feels.** "SQL you can read" names a feeling. The fix names the mechanism or a number: "`.toSQL()` returns the exact string sent to the database". If you can't restate a sentence as a concrete instruction, fact, or number, cut it. One more check: if the sentence could appear unchanged in another project's docs, it says nothing about this one. Cut it.
28. **Shorten or split dense sentences.** If the reader has to backtrack to parse a sentence, break it in two or drop clauses. One idea per sentence.
29. **Active voice.** Catch "is/are/was/were + past participle" and name the actor. "Queries are validated" becomes "the compiler validates queries". Passive is fine only when the actor is unknown or genuinely doesn't matter.
30. **Cut adverbs, or use a stronger verb.** "runs quickly" becomes "is fast" or the number. "significantly improves" becomes the measured delta. An adverb propping up a weak verb means the verb is wrong.
31. **Prefer the plain word.** "utilize" becomes "use", "leverage" becomes "use", "facilitate" becomes "help", "numerous" becomes "many", "in the event that" becomes "if". The fancier synonym is rarely clearer.
