type Project = {
  name: string,
  status: string,
  path?: string,
}

function fetchProjects() {
  const projects: Project[] = [
    { name: 'A', status: 'running', path: '/repos/a' },
    { name: 'B', status: 'running', path: '/repos/b' },
    { name: 'C', status: 'exited', path: '/repos/c' },
    { name: 'D', status: 'unknown', path: undefined },
  ]

  return { projects }
}

export async function GET() {
  return Response.json({ data: fetchProjects() })
}
