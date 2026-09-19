# v0.20.8 — Character Collaborator context budget

Character AI profile settings now distinguish three quantities:

- **Context window tokens:** total model capacity shared by input and output.
- **Text model maximum output tokens:** the model/profile output ceiling. Existing non-Collaborator Text tasks retain their current use of this setting.
- **Collaborator reply output request:** the smaller limit requested for each Collaborator Text operation. It defaults to 16,384 tokens per profile and never exceeds the model output ceiling.

Settings displays the **Collaborator input allowance** as `context window − effective reply request`. The Collaborator's input meter and send guard use the same number; requests use the corresponding effective output limit. Replies, summaries, blueprints, detailed Workspace drafts and technical fallback attempts share this rule. Vision requests are independent.

For the reported profile, 1,384,448 context and 1,000,064 maximum model output previously left 384,384 input tokens. With the 16,384 default Collaborator request, the input allowance becomes 1,368,064 tokens, so the approximately 432,662-token conversation and attachment fits the local estimate. A user can raise the request for longer drafts, which reduces input room accordingly.

The meter is an estimate, not a provider tokenizer. The provider may count input or hidden overhead differently. If context capacity is unknown, CCF continues to show an estimate without blocking the request locally.
