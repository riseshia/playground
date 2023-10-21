import React from 'react'
import ReactDOM from 'react-dom/client'
import { ChakraProvider } from '@chakra-ui/react'
import { RouterProvider, createBrowserRouter } from 'react-router-dom'

import App from './App.tsx'
import ErrorPage from './error-page.tsx'
import Projects from './routes/projects.tsx'
import Upstreams from './routes/upstreams.tsx'

const router = createBrowserRouter([
  {
    path: "/",
    element: <App />,
    errorElement: <ErrorPage />,
    children: [
      {
        element: <Projects />,
        index: true,
      },
      {
        path: "/projects",
        element: <Projects />,
      },
      {
        path: "/upstreams",
        element: <Upstreams />,
      },
    ],
  },
])

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ChakraProvider>
      <RouterProvider router={router} />
    </ChakraProvider>
  </React.StrictMode>,
)
