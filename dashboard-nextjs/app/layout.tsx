'use client'

import React from 'react'

import Link from 'next/link'

import {
  Box,
  ChakraProvider,
  Flex,
  HStack,
  IconButton,
  Stack,
  useColorModeValue,
  useDisclosure,
} from '@chakra-ui/react'
import { HamburgerIcon, CloseIcon } from '@chakra-ui/icons'

type Link = {
  name: string,
  path: string,
}

const links: Link[] = [
  { name: 'Upstreams', path: '/upstreams' },
]

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const { isOpen, onOpen, onClose } = useDisclosure()

  return (
    <html>
      <head>
        <title>Compose Admin</title>
        <meta name='viewport' content='initial-scale=1.0, width=device-width' />
        <meta charSet='utf-8' />
      </head>

      <body>
        <React.StrictMode>
          <ChakraProvider>
            <Box bg={useColorModeValue('gray.100', 'gray.900')} px={4}>
              <Flex h={16} alignItems={'center'} justifyContent={'space-between'}>
                <IconButton
                  size={'md'}
                  icon={isOpen ? <CloseIcon /> : <HamburgerIcon />}
                  aria-label={'Open Menu'}
                  display={{ md: 'none' }}
                  onClick={isOpen ? onClose : onOpen}
                />

                <HStack spacing={8} alignItems={'center'}>
                  <Box fontWeight='bold'><Link href='/'>Compose</Link></Box>

                  <HStack as={'nav'} spacing={4} display={{ base: 'none', md: 'flex' }}>
                    {links.map((link) => (
                      <Link key={link.name} href={link.path}>{link.name}</Link>
                    ))}
                  </HStack>
                </HStack>
              </Flex>

              {isOpen ? (
                <Box pb={4} display={{ md: 'none' }}>
                  <Stack as={'nav'} spacing={4}>
                    {links.map((link) => (
                      <Link key={link.name} href={link.path}>{link.name}</Link>
                    ))}
                  </Stack>
                </Box>
                ) : null}
            </Box>

            {children}
          </ChakraProvider>
        </React.StrictMode>
      </body>
    </html>
  )
}
