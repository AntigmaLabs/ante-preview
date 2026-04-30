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
  antix: [
    {
      type: 'category',
      label: 'Getting Started',
      collapsed: false,
      items: ['antix/introduction', 'antix/quickstart'],
    },
    {
      type: 'category',
      label: 'Core Concepts',
      collapsed: false,
      items: [
        'antix/concepts/routing',
        'antix/concepts/organizations',
        'antix/concepts/virtual-keys',
        'antix/concepts/endpoints',
        'antix/concepts/error-handling',
        'antix/concepts/security',
      ],
    },
    {
      type: 'category',
      label: 'Identity & Agents',
      collapsed: false,
      items: [
        'antix/concepts/ante-integration',
      ],
    },
  ],
}

export default sidebars
