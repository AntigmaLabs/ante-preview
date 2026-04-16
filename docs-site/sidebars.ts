import type { SidebarsConfig } from '@docusaurus/plugin-content-docs'

const sidebars: SidebarsConfig = {
  docs: [
    {
      type: 'category',
      label: 'Getting Started',
      collapsed: false,
      items: ['start/overview', 'start/quickstart', 'start/philosophy'],
    },
    {
      type: 'category',
      label: 'Using Ante',
      items: ['usage/tui', 'usage/headless', 'usage/serve', 'usage/gateway'],
    },
    {
      type: 'category',
      label: 'TUI Cookbook',
      items: [
        'cookbook/login',
        'cookbook/models-and-thinking',
        'cookbook/providing-context',
        'cookbook/steering',
        'cookbook/approvals',
        'cookbook/web-browsing',
      ],
    },
    {
      type: 'category',
      label: 'Configuration',
      items: [
        'configuration/providers',
        'configuration/preference',
        'configuration/permission',
        'configuration/coding-plan',
      ],
    },
    {
      type: 'category',
      label: 'Extensibility',
      items: ['extend/skills', 'extend/subagents', 'extend/memory'],
    },
    {
      type: 'category',
      label: 'Experimental',
      items: ['offline', 'agent-org'],
    },
    {
      type: 'category',
      label: 'Concepts',
      items: ['concepts/core-concepts', 'concepts/architecture', 'concepts/protocol'],
    },
    {
      type: 'category',
      label: 'Benchmarks',
      items: ['benchmarks/eval'],
    },
    {
      type: 'category',
      label: 'Reference',
      items: ['tools'],
    },
  ],
}

export default sidebars
