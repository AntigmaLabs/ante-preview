import type { Config } from '@docusaurus/types'
import type * as Preset from '@docusaurus/preset-classic'

const config: Config = {
  title: 'Ante',
  tagline: 'ai-native, cloud-native, local-first agent runtime',
  favicon: 'assets/ante2.png',
  url: 'https://ante.run',
  baseUrl: '/',

  markdown: {
    mermaid: true,
  },
  themes: ['@docusaurus/theme-mermaid'],

  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.ts',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    navbar: {
      title: 'Ante',
      logo: {
        alt: 'Ante',
        src: 'assets/ante.png',
      },
      items: [
        {
          href: 'https://antigma.ai',
          label: 'Website',
          position: 'right',
        },
        {
          href: 'https://discord.gg/pqhj3DNGz2',
          label: 'Discord',
          position: 'right',
        },
        {
          href: 'https://github.com/AntigmaLabs/ante-preview',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    prism: {
      additionalLanguages: ['bash', 'json', 'rust', 'toml'],
    },
    colorMode: {
      defaultMode: 'light',
      respectPrefersColorScheme: true,
    },
  } satisfies Preset.ThemeConfig,
}

export default config
