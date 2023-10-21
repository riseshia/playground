// import { useState } from 'react'

import {
  Box,
  Flex,
  HStack,
  IconButton,
  Stack,
  useColorModeValue,
  useDisclosure,
} from '@chakra-ui/react'
import { HamburgerIcon, CloseIcon } from '@chakra-ui/icons'
import { Link, Outlet } from 'react-router-dom'

type Link = {
  name: string,
  path: string,
}
const Links: Link[] = [
  { name: 'Projects', path: '/projects' },
  { name: 'Upstreams', path: '/upstreams' },
]

function App() {
  const { isOpen, onOpen, onClose } = useDisclosure()

  return (
    <>
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
            <Box fontWeight='bold'>Compose</Box>
            <HStack as={'nav'} spacing={4} display={{ base: 'none', md: 'flex' }}>
              {Links.map((link) => (
                <Link to={link.path}>{link.name}</Link>
              ))}
            </HStack>
          </HStack>
        </Flex>

        {isOpen ? (
            <Box pb={4} display={{ md: 'none' }}>
              <Stack as={'nav'} spacing={4}>
                {Links.map((link) => (
                  <Link to={link.path}>{link.name}</Link>
                ))}
              </Stack>
            </Box>
          ) : null}
      </Box>

      <Outlet />
    </>
  )
}

export default App
