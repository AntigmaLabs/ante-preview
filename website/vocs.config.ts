import { defineConfig } from 'vocs'
import path from 'path'

export default defineConfig({
  title: 'Ante',
  description: 'ai-native, cloud-native, local-first agent runtime',
  iconUrl: '/assets/ante2.png',
  logoUrl: {
    light: '/assets/ante.png',
    dark: '/assets/ante.png',
  },
  rootDir: 'docs',
  basePath: '/',
  css: './docs/styles.css',
  topNav: [
    { text: 'Website', link: 'https://antigma.ai' },
    { text: 'Discord', link: 'https://discord.gg/pqhj3DNGz2' },
    {
      text: 'GitHub',
      link: 'https://github.com/AntigmaLabs/ante-preview',
    },
  ],
  sidebar: [
    {
      text: 'Getting Started',
      items: [
        { text: 'Overview', link: '/start/overview' },
        { text: 'Quickstart', link: '/start/quickstart' },
        { text: 'Philosophy', link: '/start/philosophy' },
      ],
    },
    {
      text: 'Using Ante',
      items: [
        { text: 'Interactive TUI', link: '/usage/tui' },
        { text: 'Headless', link: '/usage/headless' },
        { text: 'Serve', link: '/usage/serve' },
      ],
    },
    {
      text: 'Configuration',
      items: [
        { text: 'Providers', link: '/configuration/providers' },
        { text: 'Preference', link: '/configuration/preference' },
        { text: 'Permissions', link: '/configuration/permission' },
        { text: 'Coding Plan', link: '/configuration/coding-plan' },
      ],
    },
    {
      text: 'Extensibility',
      items: [
        { text: 'Skills', link: '/extend/skills' },
        { text: 'Subagents', link: '/extend/subagents' },
        { text: 'Memory', link: '/extend/memory' },
      ],
    },
    {
      text: 'Experimental',
      items: [
        { text: 'Offline Mode', link: '/offline' },
        { text: 'Agent Organization', link: '/agent-org' },
      ],
    },
    {
      text: 'Concepts',
      items: [
        { text: 'Core Concepts', link: '/concepts/core-concepts' },
        { text: 'Architecture', link: '/concepts/architecture' },
        { text: 'Protocol', link: '/concepts/protocol' },
      ],
    },
    {
      text: 'Benchmarks',
      items: [{ text: 'Evals', link: '/benchmarks/eval' }],
    },
    {
      text: 'Reference',
      items: [{ text: 'Tools', link: '/tools' }],
    },
  ],
  vite: {
    resolve: {
      alias: {
        '~/': path.join(__dirname, 'docs/'),
      },
    },
  },
})
