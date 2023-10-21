import { execSync } from 'child_process'

import { Project } from '../../../types/common'

const defaultProjects: Project[] = [
  { name: 'A', status: 'running', path: '/repos/a' },
  { name: 'B', status: 'running', path: '/repos/b' },
  { name: 'C', status: 'exited', path: '/repos/c' },
  { name: 'D', status: 'unknown', path: undefined },
  { name: 'z', status: 'unknown', path: undefined },
]

function fetchProjectsFromDocker() {
  const stdout = execSync('docker compose ls --all --format=json').toString()

  return JSON.parse(stdout).map((project: any) => {
    return {
      name: project.Name,
      status: project.Status.split('(')[0],
      path: project.ConfigFiles,
    }
  })
}

interface ProjectByKey {
  [key: string]: Project
}

function mergeProjects(base: Project[], override: Project[]) {
  const prjByKey: ProjectByKey = {}
  override.forEach((project) => prjByKey[project.name] = project)

  let projects: Project[] = []
  base.forEach((project) => {
    if (!prjByKey[project.name]) {
      projects.push(project)
    }
  })
  override.forEach((project) => { projects.push(project) })

  return projects
}


export async function GET() {
  try {
    let projectsFromDocker = fetchProjectsFromDocker()
    const allProjects = mergeProjects(defaultProjects, projectsFromDocker)

    const projects = allProjects.sort((a, b) => { return a.name.localeCompare(b.name) })

    return Response.json({ data: { projects } })
  } catch (e: any) {
    return Response.json({ error: e.message })
  }
}

export async function DELETE(request: Request) {
  const params = await request.json()
  const projectName = params.name

  return Response.json({ data: { status: 'ok' } })
  // try {
  //   const projects = fetchProjectsFromDocker()
  //   const project = projects.find((project: Project) => {
  //     return project.name === projectName
  //   })
  //
  //   if (project && project.path) {
  //     startProject(project.path)
  //     return Response.json({ data: { status: 'ok' } })
  //   } else {
  //     return Response.json({ error: 'project not found' })
  //   }
  //
  // } catch (e: any) {
  //   return Response.json({ error: e.message })
  // }
}
