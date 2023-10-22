import { execSync } from 'child_process'

import { Project } from '../../../../types/common'

function fetchProjectsFromDocker(): Project[] {
  const stdout = execSync('docker compose ls --all --format=json').toString()

  return JSON.parse(stdout).map((project: any) => {
    return {
      name: project.Name,
      status: project.Status.split('(')[0],
      path: project.ConfigFiles,
    }
  })
}

function stopProject(path: string) {
  execSync(`docker compose -f ${path} down`)
}

export async function POST(request: Request) {
  const params = await request.json()
  const projectName = params.name

  try {
    const projects = fetchProjectsFromDocker()
    const project = projects.find((project: Project) => {
      return project.name === projectName
    })

    if (project && project.configPath) {
      stopProject(project.configPath)
      return Response.json({ data: { status: 'ok' } })
    } else {
      return Response.json({ error: 'project not found' })
    }

  } catch (e: any) {
    return Response.json({ error: e.message })
  }
}
